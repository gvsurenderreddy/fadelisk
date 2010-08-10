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
            self.conf = conf.ConfYAML(Application.conf_file_name)
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

    def parse_args(self):
        self.parser = OptionParser()

        self.parser.add_option("-c", "--conf",
            help="configuration file",
            action="store", dest="conf_file"
        )

        self.parser.add_option("-s", "--server",
            help="launch fadelisk server",
            action="store_true", dest="application_mode_server"
        )

        (self.options, self.args) = self.parser.parse_args()

    def dispatch(self):
        if self.options.application_mode_server:
            server.start(self.options, self.args, self.conf)
        else:
            client.start(self.options, self.args, self.conf)

