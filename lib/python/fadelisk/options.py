
import argparse
import sys

class ShowDefaultsAction(argparse.Action):
    def __init__(self, option_strings, dest, help=None, **kwargs):
        argparse.Action.__init__(self, option_strings, dest, nargs=0,
                                 help=help)
        self.app = kwargs['app']

    def __call__(self, parser, namespace, values, option_string=None):
        self.app.show_configuration()
        sys.exit()


class Options(object):
    """Command-line options

    Handles building of command-line parser using argparse, including
    uage info. Parses arguments and stores the results.
    """
    def __init__(self, app):
        """Initializer

        Ready the command-line parser and parse the arguments.
        """
        self.app = app
        self.build_parser()
        self.args = self.parser.parse_args()

    def build_parser(self):
        """Build the command line parser

        Construct the command-line parser and usage info.
        """
        self.parser = argparse.ArgumentParser(
            prog='fadelisk',
            description='A web server where all pages are templates.',
        )

        self.parser.add_argument('-c', '--config',
                                 help='specify a configuration file',
                                 dest='conf_file')

        self.parser.add_argument('-b', '--bind',
                                 help='TCP bind address',
                                 dest='bind_address')

        self.parser.add_argument('-p', '--port',
                                 help='TCP listen port',
                                 dest='listen_port')

        self.parser.add_argument('-g', '--loglevel',
                                 help='log level',
                                 choices=['error', 'warning', 'info', 'debug'],
                                 dest='log_level')

        self.parser.add_argument('-u', '--user',
                                 help='run server as this user',
                                 dest='process_user')

        self.parser.add_argument('-f', '--foreground',
                                 help='run server process in foreground',
                                 dest='run_in_foreground', action='store_true')

        self.parser.add_argument('-o', '--errout',
                                 help='redirect stderr to a file',
                                 dest='stderr_file')

        self.parser.add_argument('--server-header',
                                 help='server name/version for HTTP headers',
                                 dest='server_header')

        self.parser.add_argument('--show-defaults',
                                 help='print built-in application defaults',
                                 action=ShowDefaultsAction, app=self.app)

        self.parser.add_argument('action', nargs=1, type=str,
                                 choices=['start', 'stop', 'restart'],
                                 help='start, stop, or restart the server')

    def get_args(self):
        """Get parsed command-line arguments

        Returns:
            command line arguments as argparse namespace
        """
        return self.args

