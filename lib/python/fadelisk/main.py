#! /usr/bin/python2.7

"""Application runner

.. moduleauthor:: Patrick M. Jordan <patrick@fadelisk.org>

To use this runner:

 * Copy this file (as any name) into the top directory of your package.

 * Change the mode of the file to make it executable.

 * Optionally create a symbolic link anywhere in $PATH with any name.

 * In your package, export a class named Application with a method called
   run(), or a submodule/subpackage named "application" containing the class.

 * Execute the symlink to run your application.
"""

import sys
from os.path import basename, dirname, realpath
sys.dont_write_bytecode = True


class ApplicationNotFoundError(Exception): pass
"""Exception for when Application class can't be found in imported packages"""


class ApplicationRunner(object):
    def __init__(self):
        """Initializer

        Import package and locate Application class.
        """
        self.import_package()
        self.find_application()

    def import_package(self):
        """Import the package that contains this script

        Determine script's real path and get directory name to use as package
        name. Add package's parent directory to library path and attempt to
        import the package.
        """
        self.script_dir = dirname(realpath(__file__))   # might be symlink
        self.package_name = basename(self.script_dir)   # name of dir is package
        self.package_path = dirname(self.script_dir)    # parent is new path
        sys.path.insert(0, self.package_path)           # add path as first node
        __import__(self.package_name)                   # attempt import

    def find_application(self):
        """Search for an Application class in the package namespace

        :raises: ApplicationNotFoundError
        """
        namespace = sys.modules[self.package_name]

        if hasattr(namespace, 'Application'):                       # at top
            self.application = namespace.Application()
            return

        if (hasattr(namespace, 'application') and                   # in module
            hasattr(namespace.application, 'Application')):
            self.application = namespace.application.Application()
            return

        raise ApplicationNotFoundError('Need Application() or ' +   # not found
                                       'application.Application() in ' +
                                       'package %s' % name)

    def run(self):
        self.application.run()


if __name__ == '__main__':
    ApplicationRunner().run()

