
from __future__ import print_function

import os
import sys
import time
from operator import itemgetter
from os.path import dirname, join, realpath

from .daemon import Daemon
from .options import Options
from .server import FadeliskServer
from .logger import Logger
from .lockfile import Lockfile, LockfileOpenError, LockfileEstablishError, \
        LockfileStaleError, LockfileLockedError
from .conf import ConfDict, ConfYAML, ConfStack, ConfHunterFactory
from .conf import ConfNotFoundError

class Application(Daemon):
    """Fadelisk application

    The application container for the Fadelisk process. Handles
    loading configurations including command-line arguments,
    daemonizing the process, and dispatching command-line actions to
    start and stop the server.
    """

    conf_file_name = 'fadelisk.yaml'
    """The name of the configuration file."""

    conf_file_locations = [
        'conf',                     # Self-contained (relative to package)
        '/srv/www/conf',            # FHS Service-centric locations
        '/srv/www/conf/fadelisk',
        '/etc/fadelisk',            # Ubuntu, Debian, Linux Mint, Knoppix
        '/etc',                     # Red Hat, CentOS, [Open]SuSE
    ]
    """If no configuration file is specified on the command line, this
    built-in list of locations is searched in order. The first
    matching file "wins." Some values are computed later based on the
    relative location of the executable in case the applications is
    run from from a local directory (e.g., a tarball or version
    control).
    """

    default_conf = {
        'server_header': 'fadelisk/1.0',
        'bind_address': '127.0.0.1',
        'listen_port': 1066,
        'process_user': 'nobody',
        'run_in_foreground': False,
        'log_level': 'warning',
        'site_collections': ['/srv/www/sites'],
        'directory_index': [ 'index.html', 'index.htm'],
        'stderr_file': None,
        'extra_python_directories': ['/srv/www/lib/python'],
        'extra_template_directories': [],
    }
    """Default configuration: This built-in configuration is used if no
    configuration is found, and as a fallback for unspecified values.
    """

    def __init__(self):
        """Initializer

        This initializer starts the logger, parses the command line options,
        and loads the configuration. It also initializes the Daemon
        superclass using the loaded configuration. An initialized
        Application is ready to .run().
        """
        lib_dir = dirname(realpath(__file__))
        self.archive_path = realpath(join(lib_dir, '../../..'))

        self.log = Logger()
        self.log.set_level(self.default_conf['log_level'])  # from defaults
        self.log.stderr_on()

        self.options = Options(self)
        self.args = self.options.get_args()
        self.load_conf()

        sys.path.extend(self.conf.get('extra_python_directories', []))

        self.log.set_level(self.conf['log_level'])  # from final config

        Daemon.__init__(self, stderr=self.conf['stderr_file'])

    def run(self):
        """Run the Fadelisk application

        Dispatch action specified on the command line. Print usage
        information if action is invalid.
        """
        action = self.args.action[0]

        self.check_superuser()
        self.build_dispatch_table()
        try:
            action = self.dispatch_table[action]
            action()
        except KeyError:
            self.log.error('Action "%s" is not implemented yet.' %
                           self.args.action[0])
            sys.exit(2)

    def build_dispatch_table(self):
        """Build the dispatch table actions specified on the command line."""
        self.dispatch_table = {
            'start':    self.action_start,
            'stop':     self.action_stop,
            'reload':   self.action_restart,
            'restart':  self.action_restart,
        }

    def action_start(self):
        """Start the Fadelisk server

        Daemonizes, acquires a lockfile, sets process user, and runs
        the server.
        """
        if not self.conf['run_in_foreground']:
            self.daemonize()

        lock = Lockfile("fadelisk", user=self.conf['process_user'])
        try:
            lock.acquire()
        except LockfileLockedError:
            sys.exit("Lockfile present, process already running")
        except:
            sys.exit("Could not establish lock file")

        self.server = FadeliskServer(self)      # build reactor
        self.chuser(self.conf['process_user'])  # relinquish root
        self.log.stderr_off()                   # quiet after init
        self.server.run()                       # blocks

        lock.release()

    def action_stop(self):
        """Stop the Fadelisk server

        Terminates a running Fadelisk server, if possible.
        """
        lock = Lockfile("fadelisk")
        try:
            lock.kill_process()
        except LockfileStaleError:
            sys.exit("Lockfile stale, removing")
        except LockfileOpenError:
            sys.exit("No lockfile present")

    def action_restart(self):
        """Stop and start the server

        Shuts the server down, pauses briefly, then spawns a new server
        """
        self.action_stop()
        self.action_start()

    def load_conf(self):
        """Configuration loader

        Loads command-line specified configuration, or discovers
        configurations from known locations. Assembles these
        configurations (including fallback defaults and command-line
        arguments) into a configuration "stack" in order of overriding
        priority.
        """
        # Bootstrap configuration values
        default_conf = ConfDict(self.default_conf)

        # If a configuration file was specified on the command line, load it.
        if self.args.conf_file:
            application_conf = ConfYAML(self.args.conf_file,
                                      ignore_changes=True)
        else:
            # Otherwise, let the hunter try to find it.
            locations = []
            for location in self.conf_file_locations:
                if not location.startswith('/'):
                    location = join(self.archive_path, location)
                locations.append(location)
            try:
                application_conf = ConfHunterFactory(ConfYAML,
                         self.conf_file_name, locations, ignore_changes=True)
            except ConfNotFoundError:
                application_conf = {}

        # Build the stack of configurations.
        self.conf = ConfStack([application_conf, self.default_conf],
                              options=vars(self.args))

    def show_configuration(self):
        print("Configuration file name:\n    %s" % self.conf_file_name)
        print("\nConfiguration file locations:")
        for location in self.conf_file_locations:
            if location.startswith('/'):
                print("    %s" % location)
            else:
                print("    {package directory}/%s" % location)
        print("\nDefault Configuration:")
        for option, value in sorted(self.default_conf.items(),
                                    key=itemgetter(0)):
            print('    %s: %s' % (option, value))

    def check_superuser(self):
        if os.getuid():
            sys.exit("Fadelisk must be run as superuser")

    def rel_path(self, *nodes):
        if not nodes:
            return self.archive_path
        return join(self.archive_path, *nodes)

