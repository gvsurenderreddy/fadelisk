
from __future__ import print_function

import os
import sys
import pwd
import signal

from twisted.internet import reactor
from twisted.web import http, resource, server, vhost

from . import conf
from . import site

class SiteNotFoundPage(resource.ForbiddenResource):
    def __init__(self):
        resource.ErrorPage.__init__(self, http.FORBIDDEN, "No Such Site",
                          "Your request does not correspond to a known site.")

class Server(object):
    def __init__(self, application_conf):
        self.application_conf = application_conf
        self.sites = []

        self.vhost = vhost.NameVirtualHost()
        self.vhost.default=SiteNotFoundPage()
        self.gather_sites()
        self.ubersite = server.Site(self.vhost)

        reactor.listenTCP(self.application_conf['listen_port'], self.ubersite,
                          interface=self.application_conf['bind_address'])

    def run(self):
        signal.signal(signal.SIGTERM, self.stop)
        reactor.run()

    def stop(self, signum, frame):
        #reactor.callLater(0.1, reactor.stop)
        reactor.stop()

    def gather_sites(self):
        for collection in self.application_conf['site_collections']:
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
                    print('/!\\ Error while reading config for', fqdn)
                    print(str(err))
                    continue

                #-- Check if site is active.
                if not site_conf.get('site_active'):
                    print(fqdn, "is INACTIVE")
                    continue

                #-- Add site if not already found...
                if fqdn in [s.fqdn for s in self.sites]:
                    print('- Skipping site', fqdn,
                          'which was already present.')
                    continue
                # ...and not listed as an alias for another site.
                for site_ in self.sites:
                    if fqdn in site_.get_aliases():
                        print("- Site", fqdn, "already listed as alias for",
                              site_.fqdn)
                        break
                else:
                    this_site = site.Site(site_path, self.application_conf,
                                          site_conf)
                    self.vhost.addHost(fqdn, this_site.resource)
                    self.sites.append(this_site)
                    print(fqdn)

                #-- Add aliases...
                for alias in site_conf.get('site_aliases', []):
                    #   ...if not present as site...
                    if alias in [s.fqdn for s in self.sites]:
                        print(' - Alias', alias, 'for', fqdn,
                              'is already present as site')
                        continue
                    #   ...and not listed as an alias in some other site.
                    for site_ in self.sites:
                        if alias in site_.get_aliases():
                            print(" - Alias", alias,
                                  "already listed as alias for", site_.fqdn)
                            break
                    else:
                        this_site.add_alias(alias)
                        self.vhost.addHost(alias, this_site.resource)
                        print(' +', alias)

