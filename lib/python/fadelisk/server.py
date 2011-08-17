#!/usr/bin/env python

from __future__ import print_function

import os
import sys
import pwd
from twisted.internet import reactor, protocol, defer
from twisted.web import server, vhost, static
from twisted.protocols import basic

import conf
import site

class ServerControlProtocol(basic.LineReceiver):
    def lineReceived(self, line):
        if line.startswith('shutdown'):
            self.transport.loseConnection()
            reactor.callLater(0.5, reactor.stop)

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
            for site_ in os.listdir(collection):
                site_path = os.path.join(os.path.abspath(collection), site_)
                site_etc_path = os.path.join(site_path, 'etc')
                site_conf_file = os.path.join(site_etc_path, 'site.yaml')

                if not os.path.isdir(site_path):
                    continue

                if not os.path.exists(site_conf_file):
                    continue

                try:
                    print(site_)
                    site_conf = conf.ConfYAML(site_conf_file)
                except OSError as err:
                    print('/!\\ Error while reading config for', site_)
                    print(str(err))
                    continue

                # Build resource.
                this_site = site.Site(site_path, self.conf, site_conf)

                # Add site for the FQDN of the directory
                self.sites.append(this_site)
                self.vhost.addHost(site_, this_site.resource)

                # Add hosts for each aliases. Re-use the resource.
                for alias in site_conf.get('site_aliases', []):
                    print(' +', alias)
                    self.vhost.addHost(alias, this_site.resource)

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
            raise Exception, e.strerror
        if pid:
            os._exit(0)


def start(conf, args):
    return Server(conf, args).start()


