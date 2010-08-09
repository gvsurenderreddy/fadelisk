
from __future__ import with_statement
from __future__ import print_function

import os
import sys
import types
import yaml
import json

class ConfFormatError(Exception):
     def __init__(self, *args):
         Exception.__init__(self, *args)



class ConfYAML(object):
    def __init__(self, filename):
        self.filename = filename
        self.timestamp = None
        self.data = None
        self.refresh()

    def __getitem__(self, key):
        self.refresh()
        if self.data.has_key(key):
            return self.data[key]
        return None

    def __repr__(self):
        return str(self.data)

    def soft_set(self, key, value):
        if not self.data.has_key(key):
            self.data[key] = value

    def soft_update(self, data):
        for (key, value) in data:
            self.soft_set(key, value)

    def refresh(self):
        mtime = os.stat(self.filename).st_mtime
        if mtime != self.timestamp:
            with open(self.filename) as yaml_file:
                self.data = yaml.load(yaml_file)
            self.timestamp = mtime


class ConfJSON(object):
    def __init__(self, filename):
        self.filename = filename
        self.timestamp = None
        self.data = None
        self.refresh()

    def __getitem__(self, key):
        self.refresh()
        if self.data.has_key(key):
            return self.data[key]
        return None

    def __repr__(self):
        return str(self.data)

    def soft_set(self, key, value):
        if not self.data.has_key(key):
            self.data[key] = value

    def soft_update(self, data):
        for (key, value) in data:
            self.soft_set(key, value)

    def refresh(self):
        mtime = os.stat(self.filename).st_mtime
        if mtime != self.timestamp:
            with open(self.filename) as json_file:
                self.data = json.load(json_file)
            self.timestamp = mtime


class ConfList(list):
    _timestamp = None
    filename = None

    def __init__(self, filename):
        list.__init__(self)
        self.filename = filename
        self.refresh()

    def __iter__(self):
        self.refresh()
        return list.__iter__(self)

    def __getitem__(self, key):
        self.refresh()
        return list.__getitem__(self, key)

    def __getslice__(self, i=None, j=None):
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

    def __init__(self, filename):
        self.filename = filename
        self.refresh()


    def refresh(self):
        mtime = os.stat(self.filename).st_mtime
        if mtime != self._timestamp:
            with open(self.filename) as f:
                self._data = f.read()
            self._timestamp = mtime

    def contents(self):
        self.refresh()
        return self._data

    def __str__(self):
        return str(self._data)

    def __repr__(self):
        return str(self._data)

if __name__ == "__main__":
    cl = ConfList('/tmp/test.txt')
    print(ConfList(cl))


def ConfHunterFactory(cls, filename, locations=None):
    if locations == None:
        script_parent = os.path.join([os.path.dirname(sys.argv[0]), '..'])
        locations = [
            '.',
            script_parent,
            os.path.join(script_parent, 'etc')
        ]

    for location in locations:
        conf_file = os.sep.join([location, filename])
        if os.access(conf_file, os.R_OK):            # readable?
            return cls(conf_file)
        raise RuntimeError, "Could not find %s" % filename

