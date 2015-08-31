
import os
import signal

from twisted.internet import epollreactor
epollreactor.install()
from twisted.internet import reactor
from twisted.web import http, resource, server, vhost

from . import conf
from . import site

class SiteNotFoundPage(resource.ErrorPage):
    def __init__(self):
        resource.ErrorPage.__init__(self, http.FORBIDDEN, "No Such Site",
                          "Your request does not correspond to a known site.")


class CustomServerSite(server.Site):
    def __init__(self, resource, server_header):
        self.server_header = server_header
        server.Site.__init__(self, resource)

    def getResourceFor(self, request):
        request.setHeader('server', self.server_header)
        return server.Site.getResourceFor(self, request)


class Server(object):
    def __init__(self, app):
        self.app = app
        self.sites = []

        self.vhost = vhost.NameVirtualHost()
        self.vhost.default=SiteNotFoundPage()
        self.gather_sites()
        #self.ubersite = server.Site(self.vhost)
        self.ubersite = CustomServerSite(self.vhost,
                                         server_header=self.app.conf['server'])

        reactor.listenTCP(self.app.conf['listen_port'], self.ubersite,
                          interface=self.app.conf['bind_address'])

    def run(self):
        signal.signal(signal.SIGTERM, self.stop)
        reactor.run()

    def stop(self, signum, frame):
        reactor.stop()

    def gather_sites(self):
        for collection in self.app.conf['site_collections']:
            if not os.path.exists(collection):
                continue
            for fqdn in os.listdir(collection):
                #-- Build and check path
                site_path = os.path.join(os.path.abspath(collection), fqdn)
                site_etc_path = os.path.join(site_path, 'etc')
                if not os.path.isdir(site_path):
                    continue

                #-- Check for conf file
                site_conf_file = os.path.join(site_etc_path, 'site.yaml')
                if not os.path.exists(site_conf_file):
                    continue
                try:
                    site_conf = conf.ConfYAML(site_conf_file)
                except OSError as err:
                    self.app.log.error(
                        'Error reading config for %s: %s' % (fqdn, err))
                    continue

                #-- Check if site is active.
                if not site_conf.get('site_active'):
                    self.app.log.info('%s is INACTIVE' % fqdn)
                    continue

                #-- Add site if not already found...
                if fqdn in [s.fqdn for s in self.sites]:
                    self.app.log.warning('- Skipping site %s which was ' +
                                         'already present.' % fqdn)
                    continue
                # ...and not listed as an alias for another site.
                for site_ in self.sites:
                    if fqdn in site_.get_aliases():
                        self.app.log.warning('Site %s already listed as ' +
                                             'alias for %s'
                                             % (fqdn, site_.fqdn))
                        break
                else:
                    this_site = site.Site(site_path, site_conf, self.app)
                    self.vhost.addHost(fqdn, this_site.resource)
                    self.sites.append(this_site)
                    self.app.log.info("Loaded site %s" % fqdn)

                #-- Add aliases...
                for alias in site_conf.get('site_aliases', []):
                    #   ...if not present as site...
                    if alias in [s.fqdn for s in self.sites]:
                        self.app.log.warning('Alias %s for %s is already ' +
                                             'present as site' % (alias, fqdn))
                        continue
                    #   ...and not listed as an alias in some other site.
                    for site_ in self.sites:
                        if alias in site_.get_aliases():
                            self.app.log.warning('Alias %s already listed ' +
                                                 'as alias for %s' %
                                                 (alias, site_.fqdn))
                            break
                    else:
                        this_site.add_alias(alias)
                        self.vhost.addHost(alias, this_site.resource)
                        self.app.log.info('Added alias %s for %s' %
                                          (alias, site_.fqdn))

