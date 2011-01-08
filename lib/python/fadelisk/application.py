#!/usr/bin/env python

import os
import sys
from optparse import OptionParser

import conf
import client
import server

class Application(object):
    conf_file_name = 'fadelisk.yaml'
    def __init__(self):
        self.parse_args()
        self.load_conf()
        self.dispatch()

    def load_conf(self):
        if self.options.conf_file:
            self.conf = conf.ConfYAML(Application.conf_file_name,
                                      ignore_changes=True)
        else:
            script_parent = os.path.join(os.path.dirname(sys.argv[0]), '..')
            locations = [
                '/etc/fadelisk',        # Ubuntu, Debian, Linux Mint, Knoppix
                '/etc',                 # Red Hat, SuSE
                '/srv/www/etc',         # FHS Service-centric location 
                os.path.join(script_parent, 'etc'), # Development
                script_parent,          # Distribution?
            ]
            self.conf = conf.ConfHunterFactory(
                conf.ConfYAML, Application.conf_file_name, locations)

        #-- Update missing values with hard-coded defaults.
        # Independent
        self.conf.soft_update({
            'server': 'fadelisk 1.0 (barndt)',
            'listen_port': 1066,
            'bind_address': 'localhost',
            'process_user': 'www-data',
            'site_collections': ['/srv/www/site'],
            'charm': {},
            'directory_index': 'index.html',
        })
        # Dependent
        self.conf.soft_update({
            'control_port': self.conf['listen_port']+1,
            'control_address': self.conf['bind_address']
        })

    def parse_args(self):
        self.parser = OptionParser()

        self.parser.add_option("-c", "--conf",
            help="configuration file",
            action="store", dest="conf_file"
        )

        (self.options, self.args) = self.parser.parse_args()

    def dispatch(self):
        command = self.args[0]
        if command == 'start':
            server.start(self.options, self.args, self.conf)
        elif command == 'stop':
            client.start(self.options, self.args, self.conf)
        else:
            print("usage: fadelisk [options] start | stop | client | command")

