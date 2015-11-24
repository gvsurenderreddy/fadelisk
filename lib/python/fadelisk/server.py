
import os
import signal
import platform

# Mapping of fast reactors and the systems that support them
fast_reactors = {
    'epollreactor': ['Linux'],
    'kqueuereactor': ['OpenBSD'],
}

# Import a faster reactor, if one is available
for fast_reactor, platform_systems in fast_reactors.iteritems():
    if platform.system() in platform_systems:
        tw_inet = __import__('twisted.internet', fromlist=[fast_reactor])
        tw_inet.__dict__[fast_reactor].install()
        break

from twisted.internet import reactor
from twisted.web import resource, server, vhost

from . import conf
from .site import FadeliskSite
from .resource import SiteNotFoundResource


class FadeliskServer(server.Site):
    def __init__(self, app):
        self.app = app

        self.vhost = vhost.NameVirtualHost()
        server.Site.__init__(self, self.vhost)

        self.vhost.default=SiteNotFoundResource(self.app)
        self.gather_sites()

        self.server_header = app.conf.get('server_header', 'fadelisk/1.0')

        reactor.listenTCP(app.conf['listen_port'], self,
                          interface=app.conf['bind_address'])

    def run(self):
        signal.signal(signal.SIGTERM, self.stop)
        reactor.run()

    def stop(self):
        reactor.stop()

    def stop_on_signal(self, signum, frame):
        self.stop()

    def gather_sites(self):
        self.sites = []
        for collection in self.app.conf['site_collections']:
            if not os.path.exists(collection):
                continue
            for fqdn in os.listdir(collection):
                #-- Build and check path
                site_path = os.path.join(os.path.abspath(collection), fqdn)
                site_conf_path = os.path.join(site_path, 'conf')
                if not os.path.isdir(site_path):
                    continue

                #-- Check for conf file
                site_conf_file = os.path.join(site_conf_path, 'site.yaml')
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
                for site in self.sites:
                    if fqdn in site.aliases:
                        self.app.log.warning('Site %s already listed as ' +
                                             'alias for %s'
                                             % (fqdn, site.fqdn))
                        break
                else:
                    this_site = FadeliskSite(site_path, site_conf, self.app)
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
                    for site in self.sites:
                        if alias in site.aliases:
                            self.app.log.warning('Alias %s already listed ' +
                                                 'as alias for %s' %
                                                 (alias, site.fqdn))
                            break
                    else:
                        this_site.aliases.append(alias)
                        self.vhost.addHost(alias, this_site.resource)
                        self.app.log.info('Added alias %s for %s' %
                                          (alias, site.fqdn))
        if not self.sites:
            self.app.log.warning('No sites could be loaded.')

    def getResourceFor(self, request):
        request.setHeader('server', self.server_header)
        return server.Site.getResourceFor(self, request)

