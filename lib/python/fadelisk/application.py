
from __future__ import print_function

import os
import sys
from optparse import OptionParser

from twisted.internet import pollreactor
pollreactor.install()

import conf
import server
import client

class Application(object):
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
        'server': 'fadelisk 1.0 (barndt)',
        'listen_port': 1066,
        'bind_address': '127.0.0.1',
        'process_user': 'www-data',
        'site_collections': ['/srv/www/site'],
        'directory_index': 'index.html',
    }

    def __init__(self):
        self.parse_args()
        self.load_conf()
        self.dispatch()

    def load_conf(self):
        #-- Update default configuration with some dependent options
        default_conf = conf.ConfDict(Application.default_conf)
        default_conf.soft_update({
            'control_port': default_conf['listen_port']+1,
            'control_address': default_conf['bind_address']
        })

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
        usage = 'usage: %prog [options] start | stop | client | command'
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

    def command_not_implemented(self, conf, args):
        print('Command "%s" is not implemented yet.' % args[0])

    def build_dispatch_table(self):
        self.dispatch_table = {
            'start':    server.start,
            'stop':     client.start,
            'client':   self.command_not_implemented,
            'command':  self.command_not_implemented,
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
        except KeyError:
            print(Application.usage)
            sys.exit(1)

        execute(self.conf, self.args)

