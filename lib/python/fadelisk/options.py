
from argparse import ArgumentParser

class Options(object):
    """Command-line options

    Handles building of command-line parser using argparse, including
    uage info. Parses arguments and stores the results.
    """
    def __init__(self):
        """Initializer

        Ready the command-line parser and parse the arguments.
        """
        self.build_parser()
        self.args = self.parser.parse_args()

    def build_parser(self):
        """Build the command line parser

        Construct the command-line parser and usage info.
        """
        self.parser = ArgumentParser(
            prog='fadelisk',
            description='A web server where all pages are templates.',
        )
        self.parser.add_argument('-c', '--config', dest='conf_file',
                                 help='specify a configuration file')
        self.parser.add_argument('-b', '--bind', dest='bind_address',
                                 help='bind address')
        self.parser.add_argument('-p', '--port', dest='listen_port',
                                 help='listen port')
        self.parser.add_argument('-g', '--loglevel', dest='log_level',
                                 help='log at: error, warning, info, debug')
        self.parser.add_argument('-u', '--user', dest='process_user',
                                 help='run server as this user')
        self.parser.add_argument('-o', '--errout', dest='stderr_file',
                                 help='direct stderr to this file')
        self.parser.add_argument('--server', dest='server',
                                 help='use this server in HTTP headers')

        self.parser.add_argument('action', nargs=1, type=str,
                                 help='actions: start, stop')

    def get_args(self):
        """Get parsed command-line arguments

        Returns:
            command line arguments as argparse namespace
        """
        return self.args

