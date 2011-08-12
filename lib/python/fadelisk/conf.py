
from __future__ import with_statement

import os
import sys
import yaml
import json

class ConfFormatError(Exception):
     def __init__(self, *args):
         Exception.__init__(self, *args)

class ConfDict(object):
    def __init__(self):
        self.data = {}

    def data(self):
        return self.data

    def __getitem__(self, key):
        return self.data[key]

    def __iter__(self):
        return iter(self.data)

    def __len__(self):
        return len(self.data)

    def __contains__(self, key):
        return key in self.data

    def __repr__(self):
        return repr(self.data)

    def __str__(self):
        return str(self.data)

    def iteritems(self):
        return self.data.iteritems()

    def items(self):
        return self.data.items()

    def get(self, key, default=None):
        return self.data.get(key, default)

    def soft_set(self, key, value):
        self.data.setdefault(key, value)

    def soft_update(self, data):
        for key, value in data.items():
            self.soft_set(key, value)

class ConfYAML(ConfDict):
    def __init__(self, filename, ignore_changes=False):
        ConfDict.__init__(self)
        self.filename = filename
        self.ignore_changes = ignore_changes
        self.timestamp = None
        self.refresh()

    def __getitem__(self, key):
        if not self.ignore_changes:
            self.refresh()
        return ConfDict.__getitem__(self, key)

    def get(self, key, default=None):
        if not self.ignore_changes:
            self.refresh()
        return ConfDict.get(self, key, default)

    def refresh(self):
        mtime = os.stat(self.filename).st_mtime
        if mtime != self.timestamp:
            with open(self.filename) as yaml_file:
                self.data = yaml.load(yaml_file)
            self.timestamp = mtime


class ConfJSON(ConfDict):
    def __init__(self, filename, ignore_changes=False):
        ConfDict.__init__(self)
        self.filename = filename
        self.ignore_changes = ignore_changes
        self.timestamp = None
        self.refresh()

    def __getitem__(self, key):
        if not self.ignore_changes:
            self.refresh()
        return ConfDict.__getitem__(self, key)

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
        self.refresh()

    def refresh(self):
        mtime = os.stat(self.filename).st_mtime
        if mtime != self._timestamp:
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
        raise RuntimeError, "Could not find %s" % filename

