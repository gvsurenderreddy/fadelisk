#!/usr/bin/env python

from __future__ import print_function

import os
import sys
from optparse import OptionParser

import conf
import client
import server

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
        '@PARENT@/etc',         # Self-contained
        '@PARENT@',             # Distribution?
    ]
    conf_file_name = 'fadelisk.yaml'

    # Options are later combined from the configuration file and command line
    # parameters. In addition, parameters that depend on other parameters
    # are computed and added last, if necessary.
    default_conf = {
        'server': 'fadelisk 1.0 (barndt)',
        'listen_port': 1066,
        'bind_address': 'localhost',
        'process_user': 'www-data',
        'site_collections': ['/srv/www/site'],
        #'charm': {},
        'directory_index': 'index.html',
    }

    def __init__(self):
        self.parse_args()
        self.load_conf()
        self.dispatch()

    def load_conf(self):
        #-- If a configuration file was specified on the command line, load it.
        if self.options.conf_file:
            self.conf = conf.ConfYAML(self.options.conf_file,
                                      ignore_changes=True)
            return

        #-- Otherwise, search for the file.
        # Compute script location and interpolate into list of locations.
        script_parent = os.path.realpath(
            os.path.join(os.path.dirname(sys.argv[0]), '..'))
        locations = []
        for location in Application.conf_file_locations:
            if location.startswith('@PARENT@'):
                location = script_parent + location[8:]
            locations.append(location)
        self.conf = conf.ConfHunterFactory(conf.ConfYAML,
                                           Application.conf_file_name,
                                           locations,
                                           ignore_changes=True)

        # TODO: Hard-update some options from the command line.
        # ...no options yet.

        #-- Update missing values with hard-coded defaults.
        # Independent
        self.conf.soft_update(Application.default_conf)
        # Dependent
        self.conf.soft_update(
            {
                'control_port': self.conf['listen_port']+1,
                'control_address': self.conf['bind_address']
            }
        )

    def parse_args(self):
        usage = 'usage: %prog [options] start | stop | client | command'
        version = '%prog 1.0 (barndt)'
        self.parser = OptionParser(usage=usage, version=version)
        self.parser.add_option("-c", "--conf",
            help="configuration file",
            action="store", dest="conf_file"
        )
        (self.options, self.args) = self.parser.parse_args()

    def dispatch(self):
        command = self.args[0]
        if command == 'start':
            server.start(self.conf, self.args)
        elif command == 'stop':
            client.start(self.conf, self.args)
        else:
            print("usage: fadelisk [options] start | stop | client | command")

