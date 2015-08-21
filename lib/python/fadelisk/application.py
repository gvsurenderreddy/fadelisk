
from __future__ import print_function

import os
import sys
import pwd
from optparse import OptionParser

from twisted.internet import pollreactor
pollreactor.install()

from . import conf
from . import server
from . import lockfile
from . import daemon
from . import logger

class Application(daemon.Daemon):
    # If no configuration file is specified on the command line, this built-in
    # list of locations is searched. Some values are computed later based on
    # the relative location of the executable, i.e., argv[0].
    # For safety, do not include the current directory.
    conf_file_locations = [
        '/etc/fadelisk',        # Ubuntu, Debian, Linux Mint, Knoppix
        '/etc',                 # Red Hat, SuSE
        '/srv/www/etc',         # FHS Service-centric location 
        # These values are interpolated at runtime.
        '@PARENT@/etc/fadelisk',# Self-contained
        '@PARENT@',             # Distribution?
    ]
    conf_file_name = 'fadelisk.yaml'
    usage = 'usage: fadelisk [options] start | stop | client | command'

    # Options are later combined from the configuration file and command line
    # parameters. In addition, parameters that depend on other parameters
    # are computed and added last, if necessary.
    default_conf = {
        'verbose': False,
        'log_level': 'warning',
        'server': 'fadelisk 1.0 (barndt)',
        'listen_port': 1066,
        'bind_address': '127.0.0.1',
        'process_user': 'www-data',
        'site_collections': ['/srv/www/site'],
        'directory_index': 'index.html',
    }

    def __init__(self):
        daemon.Daemon.__init__(self, stderr=None)
        self.log = logger.Logger()
        self.log.set_level("warning")
        self.log.stderr_on()
        self.parse_args()
        self.load_conf()
        self.log.set_level(self.conf['log_level'])

    def run(self):
        self.dispatch()

    def start(self):
        self.daemonize()

        lock = lockfile.Lockfile("fadelisk")
        lock.acquire()
        lock.chown_lockfile(self.conf['process_user'])

        self.server = server.Server(self.conf, self.args)   # build reactor
        self.chuser(self.conf['process_user'])              # relinquish root
        self.log.stderr_off()                               # quiet after init
        self.server.run()                                   # run() blocks here

        lock.release()

    def stop(self):
        lock = lockfile.Lockfile("fadelisk")
        try:
            lock.kill_process()
        except IOError:
            self.log.error("No lockfile present")
            sys.exit(1)

    def load_conf(self):
        #-- Bootstrap configuration values
        default_conf = conf.ConfDict(Application.default_conf)

        #-- If a configuration file was specified on the command line, load it.
        if self.options.conf_file:
            application_conf = conf.ConfYAML(self.options.conf_file,
                                      ignore_changes=True)
        else:
            #-- Otherwise, let the hunter try to find it.
            # Compute script location and interpolate into list of locations.
            script_path = os.path.realpath(sys.argv[0])
            script_dir = os.path.realpath(os.path.dirname(script_path))
            script_parent = os.path.realpath(os.path.join(script_dir, '..'))
            locations = []
            for location in Application.conf_file_locations:
                if location.startswith('@PARENT@'):
                    location = script_parent + location[8:]
                locations.append(location)
            try:
                application_conf = conf.ConfHunterFactory(conf.ConfYAML,
                                                   Application.conf_file_name,
                                                   locations,
                                                   ignore_changes=True)
            except conf.ConfNotFoundError:
                # If the hunter can't find it, fall back to an empty ConfDict
                application_conf = conf.ConfDict()

        # Build the stack of configurations.
        self.conf = conf.ConfStack([application_conf, default_conf],
                                   optparse=self.options.__dict__)

    def parse_args(self):
        usage = 'usage: %prog [options] start | stop'
        version = '%prog 1.0 (barndt)'
        self.parser = OptionParser(usage=usage, version=version)
        self.parser.add_option("-c", "--conf",
                               help="configuration file",
                               action="store",
                               dest="conf_file")
        self.parser.add_option("-v", "--verbose",
                               help="display more detailed information",
                               action="store_true",
                               dest="verbose",
                              )
        (self.options, self.args) = self.parser.parse_args()

    def command_not_implemented(self):
        print('Command "%s" is not implemented yet.' % self.args[0])

    def build_dispatch_table(self):
        self.dispatch_table = {
            'start':    self.start,
            'stop':     self.stop,
            'restart':  self.command_not_implemented,
        }

    def dispatch(self):
        if not self.args:
            print(Application.usage)
            sys.exit(1)
        command = self.args[0]

        self.build_dispatch_table()
        execute = None
        try:
            execute = self.dispatch_table[command]
            execute()
        except KeyError:
            print(Application.usage)
            sys.exit(1)


