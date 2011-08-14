
from __future__ import with_statement
from __future__ import print_function

import os
import sys
import yaml
import json
import threading

class ConfNotFoundError(Exception):
    def __init__(self, *args):
        Exception.__init__(self, *args)


class ConfFormatError(Exception):
    def __init__(self, *args):
        Exception.__init__(self, *args)


class ConfDict(dict):
    def __init__(self, *args, **kwargs):
        dict.__init__(self, *args, **kwargs)
        self.lock = threading.Lock()

    def soft_update(self, data):
        for key, value in data.items():
            self.setdefault(key, value)

    def replace(self, data):
        with self.lock:
            self.clear()
            self.update(data)


class ConfDynamicDict(ConfDict):
    def __init__(self, ignore_changes=False):
        ConfDict.__init__(self)
        self.ignore_changes = ignore_changes
        self.timestamp = None

    def abort_if_dynamic(self):
        if self.ignore_changes:
            return
        raise RuntimeError, 'Attempted to alter a dynamic configuration'

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
        ConfDynamicDict.__init__(self, ignore_changes)
        self.filename = filename
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
                data = yaml.load(yaml_file) or {}
            if not isinstance(data, dict):
                raise ConfFormatError('ConfYAML target must be a dictionary')
            self._replace(data)
            self.timestamp = mtime


class ConfJSON(ConfDynamicDict):
    def __init__(self, filename, ignore_changes=False):
        ConfDynamicDict.__init__(self, ignore_changes)
        self.filename = filename
        self.refresh()

    def __getitem__(self, key):
        if not self.ignore_changes:
            self.refresh()
        return ConfDynamicDict.__getitem__(self, key)

    def refresh(self):
        mtime = os.stat(self.filename).st_mtime
        if mtime != self.timestamp:
            with open(self.filename) as json_file:
                self.data = json.load(json_file)
            self.timestamp = mtime


class ConfList(list):
    _timestamp = None
    filename = None

    def __init__(self, filename, ignore_changes=False):
        list.__init__(self)
        self.filename = filename
        self.ignore_changes = ignore_changes
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
        if mtime != self._timestamp:
            with self.lock:
                with open(self.filename) as f:
                    self[:] = [line for line in f]
                self._timestamp = mtime


class ConfFileContents(object):
    _timestamp = None
    _data = None

    filename = None

    def __init__(self, filename, ignore_changes=False):
        self.filename = filename
        self.ignore_changes = ignore_changes
        self.lock = threading.Lock()
        self.refresh()

    def refresh(self):
        mtime = os.stat(self.filename).st_mtime
        if mtime != self._timestamp:
            with self.lock:
                with open(self.filename) as f:
                    self._data = f.read()
                self._timestamp = mtime

    def contents(self):
        if not self.ignore_changes:
            self.refresh()
        return self._data

    def __str__(self):
        return str(self._data)


def ConfHunterFactory(cls, filename, locations=None, ignore_changes=False):
    if locations == None:
        script_parent = os.path.join([os.path.dirname(sys.argv[0]), '..'])
        locations = [
            os.path.join(script_parent, 'etc'),
            script_parent,
            '.',
        ]

    for location in locations:
        conf_file = os.path.join(location, filename)
        if os.access(conf_file, os.R_OK):            # readable?
            return cls(conf_file, ignore_changes=ignore_changes)
        raise ConfNotFoundError, "Could not find %s" % filename

