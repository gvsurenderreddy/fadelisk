
from __future__ import print_function

import os
import sys
import pwd
from twisted.internet import reactor, protocol, defer
from twisted.web import server, vhost, static
from twisted.protocols import basic

from . import conf
from . import site

class ServerControlProtocol(basic.LineReceiver):
    def lineReceived(self, line):
        if line.startswith('shutdown'):
            self.transport.loseConnection()
            reactor.callLater(0.1, reactor.stop)

class ServerControlFactory(protocol.ServerFactory):
    protocol = ServerControlProtocol

class Server(object):
    def __init__(self, conf, args):
        self.args = args
        self.conf = conf
        self.sites = []

        self.vhost = vhost.NameVirtualHost()
        self.vhost.default=static.File("/var/www")
        self.gather_sites()
        self.ubersite = server.Site(self.vhost)

    def start(self):
        pwent = pwd.getpwnam(self.conf['process_user'])
        self.fork_process()
        self.reopen_std_streams()
        os.setsid()                # become process group leader

        #-- Open logs

        #-- Establish listening ports
        reactor.listenTCP(
            self.conf['listen_port'],
            self.ubersite,
            interface=self.conf['bind_address']
        )
        reactor.listenTCP(
            self.conf['control_port'],
            ServerControlFactory(),
            interface=self.conf['control_address']
        )

        #-- Relinquish privileges
        os.setgid(pwent.pw_gid)
        os.setuid(pwent.pw_uid)

        #-- Start the reactor.
        reactor.run()

    def gather_sites(self):
        for collection in self.conf['site_collections']:
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

                #-- Check if site is online.
                if not site_conf.get('site_online'):
                    print(fqdn, "is OFFLINE")
                    # TODO, possibly: provide offline resource.
                    continue

                #-- Add site if not already found...
                if fqdn in [s.fqdn for s in self.sites]:
                    print('- Skipping site', fqdn, 'which was already present.')
                    continue
                # ...and not listed as an alias for another site.
                for site_ in self.sites:
                    if fqdn in site_.get_aliases():
                        print("- Site", fqdn, "already listed as alias for",
                              site_.fqdn)
                        break
                else:
                    this_site = site.Site(site_path, self.conf, site_conf)
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

    def reopen_std_streams(self):
        null_fd = os.open('/dev/null', os.O_RDWR)

        # stdin/stdout on a forked process should have an assured
        # desination instead of a possibly vanishing controlling
        # TTY. Closure or redirection to the null device are both
        # good solutions. Note also that processes launched via
        # SSH will appear to hang instead of forking, because SSH
        # is waiting for closure or more forthcoming data on
        # these FDs. Merely redirecting sys.std* is inadequate
        # because copies of the original FDs are preserved in
        # sys.__std*__ and remain open unless explicitely closed.

        #-- Method 1: Extreme, full closure.
        # Issue: The application may have valid FDs open.
        # try:
        #     max_fd = os.sysconf("SC_OPEN_MAX")
        # except:
        #     max_fd = 1024
        # os.closerange(0, max_fd+1)

        #-- Method 2: Limited closure
        # The application may already have valid and important FDs open.
        # Only reopen stdin. Note that os.dup2() closes an FD before copy,
        # if necessary -- but not if the FDs are the same. Don't touch
        # stderr,  since it is needed for early exception handling and
        # doesn't affect programs that might wait for open handles to
        # be closed, such as SSH.
        os.dup2(null_fd, sys.__stdin__.fileno())
        os.dup2(null_fd, sys.__stdout__.fileno())

        # If FDs were closed earlier, null_fd may have been
        # allocated FD 0 or 1 by chance. This condition is OK. If
        # it was beyond stderr (i.e., the FD number was greater
        # than 2), it can be closed as a courtesy since it has
        # already been dup2()ed.
        if (null_fd > sys.__stdout__.fileno()):
             os.close(null_fd)

    def fork_process(self):
        try:
            pid = os.fork()
        except OSError as e:
            raise Exception(e.strerror)
        if pid:
            os._exit(0)


def start(conf, args):
    server = Server(conf, args)
    server.start()
    return server

