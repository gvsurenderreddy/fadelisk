#!/usr/bin/env python


import os
import sys
#import time
#import signal
#import string
#import subprocess

#from twisted.application import internet, service
#from twisted.web import script, resource
from twisted.internet import reactor, protocol, defer
from twisted.web import server, vhost, static
from twisted.protocols import basic

import conf
import site

class ServerConf(conf.ConfYAML):
    main_parent = os.path.join(os.path.dirname(sys.argv[0]), '..')
    file_name = 'fadelisk.yaml'
    file_locations = [
        '/etc/fadelisk',             # Ubuntu, Debian, Linux Mint, Knoppix
        '/etc',                      # Red Hat, SuSE
        '/srv/www/etc',              # FHS Service-centric location 
        os.path.join(os.path.dirname(sys.argv[0]), '..') # Development
    ]

    def __init__(self):
        self.load_conf()

    def load_conf(self):
        for location in ServerConf.file_locations:
            print "*", location
            config_file = os.path.join(location, ServerConf.file_name)
            if os.access(config_file, os.R_OK):            # readable?
                conf.ConfYAML.__init__(self, config_file)  # init parent
                return

        raise RuntimeError, "Could not find and load %s" % ServerConf.file_name

class ServerControlProtocol(basic.LineReceiver):
    def lineReceived(self, line):
        if line.startswith('shutdown'):
            self.transport.loseConnection()
            reactor.callLater(0.5, reactor.stop)

class ServerControlFactory(protocol.ServerFactory):
    protocol = ServerControlProtocol

class Server(object):
    def __init__(self, options, args):
        self.conf = ServerConf()

        self.vhost = vhost.NameVirtualHost()
        self.vhost.default=static.File("/var/www/nginx-default")

        self.gather_sites()
        self.ubersite = server.Site(self.vhost)

    def start(self):
        self.fork_process()
        self.reopen_std_streams()
        os.setsid()                # become process group leader
        # Bring sites online if enabled
        # Maybe TCP command line listener?
        reactor.listenTCP(
            self.conf['listen_port'] or 1066,
            self.ubersite,
            interface=(self.conf['bind_address'] or 'localhost')
        )
        reactor.listenTCP(
            self.conf['control_port'] or 1067,
            ServerControlFactory(),
            interface=(self.conf['control_address'] or 'localhost')
        )
        os.setgid(33)
        os.setuid(33)
        reactor.run()
        # Wait for reactor to finish.
        # Clean up.

    def gather_sites(self):
        self.sites = []
        try:
            self.collections = self.conf['site_collections']
        except:
            self.collections = [ '/srv/www/site' ]

        for collection in self.collections:
            for site_ in os.listdir(collection):
                full_path = os.path.join(os.path.abspath(collection), site_)
                if os.path.isdir(full_path):
                    try:
                        this_site = site.Site(full_path, conf)
                        self.sites.append(this_site)
                        self.vhost.addHost(site_, this_site.resource)
                        print(site_)
                    except site.NotFadeliskSiteError:
                        pass

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
        # The application may already have valid and important FDs open.  Only
        # reopen stdin. Note that os.dup2() closes an FD before copy, if
        # necessary -- but not if the FDs are the same. Don't touch stderr,
        # since it doesn't harm SSH and it is needed for early exception
        # handling.
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

    def set_proc_title(self, title):
        # prctl(15, ...) is PR_SET_NAME
        try:
            import ctypes
            libc = ctypes.CDLL('libc.so.6')
            libc.prctl(15, title, 0, 0, 0)
        except:
            try:
                import dl
                libc = dl.open('/lib/libc.so.6')
                libc.call('prctl', 15, '%s\0' % title, 0, 0, 0)
            except:
                pass

def start(options, args):
    Server(options, args).start()



