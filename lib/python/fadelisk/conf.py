
from __future__ import with_statement

import os
import sys
import json
import threading
import yaml
try:
    from yaml import CLoader as YAMLLoader
except ImportError:
    from yaml import Loader as YAMLLoader

class ConfNotFoundError(Exception): pass
class ConfFormatError(Exception): pass
class ConfUpdateError(Exception): pass

class ConfDict(dict):
    def __init__(self, *args, **kwargs):
        dict.__init__(self, *args, **kwargs)
        self.lock = threading.Lock()

    def soft_update(self, data):
        for key, value in list(data.items()):
            self.setdefault(key, value)

    def replace(self, data):
        with self.lock:
            self.clear()
            self.update(data)


class ConfDynamicDict(ConfDict):
    def __init__(self, ignore_changes=False):
        ConfDict.__init__(self)
        self.ignore_changes = ignore_changes

    def abort_if_dynamic(self):
        if self.ignore_changes:
            return
        raise ConfUpdateError('Attempted to alter a dynamic configuration')

    def __setitem__(self, key, value):
        self.abort_if_dynamic()
        ConfDict.__setitem__(self, key, value)

    def setdefault(self, key, value):
        self.abort_if_dynamic()
        ConfDict.setdefault(self, key, value)

    def soft_update(self, data):
        self.abort_if_dynamic()
        ConfDict.soft_update(self, data)

    def _replace(self, data):
        ConfDict.replace(self, data)

    def replace(self, data):
        self.abort_if_dynamic()
        self._replace(data)

    # TODO: Also protect:
    # pop
    # popitem
    # __delitem__

class ConfYAML(ConfDynamicDict):
    def __init__(self, filename, ignore_changes=False):
        ConfDynamicDict.__init__(self, ignore_changes=ignore_changes)
        self.filename = filename

        self.timestamp = None
        self.refresh()

    def __getitem__(self, key):
        if not self.ignore_changes:
            self.refresh()
        return ConfDynamicDict.__getitem__(self, key)

    def get(self, key, default=None):
        if not self.ignore_changes:
            self.refresh()
        return ConfDynamicDict.get(self, key, default)

    def refresh(self):
        mtime = os.stat(self.filename).st_mtime
        if mtime != self.timestamp:
            with open(self.filename) as yaml_file:
                data = yaml.load(yaml_file, Loader=YAMLLoader) or {}
            if not isinstance(data, dict):
                raise ConfFormatError('ConfYAML target must be a dictionary')
            self._replace(data)
            self.timestamp = mtime


class ConfJSON(ConfDynamicDict):
    def __init__(self, filename, ignore_changes=False):
        ConfDynamicDict.__init__(self, ignore_changes)
        self.filename = filename

        self.timestamp = None
        self.refresh()

    def __getitem__(self, key):
        if not self.ignore_changes:
            self.refresh()
        return ConfDynamicDict.__getitem__(self, key)

    def refresh(self):
        mtime = os.stat(self.filename).st_mtime
        if mtime != self.timestamp:
            with open(self.filename) as json_file:
                self._replace(json.load(json_file))
            self.timestamp = mtime


class ConfList(list):
    def __init__(self, filename, ignore_changes=False):
        list.__init__(self)
        self.filename = filename
        self.ignore_changes = ignore_changes

        self.timestamp = None
        self.lock = threading.Lock()
        self.refresh()

    def __iter__(self):
        if not self.ignore_changes:
            self.refresh()
        return list.__iter__(self)

    def __getitem__(self, key):
        if not self.ignore_changes:
            self.refresh()
        return list.__getitem__(self, key)

    def __getslice__(self, i=None, j=None):
        if not self.ignore_changes:
            self.refresh()
        return list.__getslice__(self, i, j)

    def refresh(self):
        mtime = os.stat(self.filename).st_mtime
        if mtime != self.timestamp:
            with self.lock:
                with open(self.filename) as f:
                    self[:] = [line for line in f]
                self.timestamp = mtime


class ConfFileContents(object):
    def __init__(self, filename, ignore_changes=False):
        self.filename = filename
        self.ignore_changes = ignore_changes

        self.timestamp = None
        self.data = None
        self.lock = threading.Lock()
        self.refresh()

    def refresh(self):
        mtime = os.stat(self.filename).st_mtime
        if mtime != self.timestamp:
            with self.lock:
                with open(self.filename) as f:
                    self.data = f.read()
                self.timestamp = mtime

    def contents(self):
        if not self.ignore_changes:
            self.refresh()
        return self.data

    def __str__(self):
        return str(self.data)


class ConfStack(object):
    def __init__(self, stack, options={}):
        self.stack = stack
        self.options = options

    def __getitem__(self, key):
        # Values from argparse/optparse must be handled specially because
        # keys appear even if a given option hasn't been specified on the
        # command line. Check for None instead of looking for the presence
        # of a key.
        try:
            if self.options[key] != None:
                return self.options[key]
        except KeyError:
            pass

        # Check the rest of the stack in order. The first matching key
        # is returned.
        for conf in self.stack:
            if key in conf:
                return conf[key]

        raise KeyError('%s not in configuration stack' % key)

    def get(self, key, default=None):
        try:
            return self.__getitem__(key)
        except KeyError:
            return default


def ConfHunterFactory(cls, filename, locations=None, ignore_changes=False):
    if not locations:
        lib_dir = dirname(realpath(__file__))
        self.archive_path = realpath(join(lib_dir, '../../..'))

        script_parent = os.path.join([os.path.dirname(sys.argv[0]), '..'])
        locations = [os.path.join(script_parent, 'conf'), script_parent, '.']

    for location in locations:
        conf_file = os.path.join(location, filename)
        if os.access(conf_file, os.R_OK):            # readable?
            return cls(conf_file, ignore_changes=ignore_changes)
    raise ConfNotFoundError("Could not find %s" % filename)

