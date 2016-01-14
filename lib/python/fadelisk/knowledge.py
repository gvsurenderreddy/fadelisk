
from os.path import dirname, exists, join, realpath
import yaml
try:
        from yaml import CLoader as YAMLLoader
except ImportError:
        from yaml import Loader as YAMLLoader

from .conf import ConfYAML

class KnowledgeNotFound(Exception): pass

class Knowledge(object):
    def __init__(self, site):
        self.site = site

        self.dirs = []
        possible_dirs = [
            self.site.app.rel_path('lib', 'knowledge'),
            site.rel_path('lib', 'knowledge'),
            site.rel_path('knowledge'),
            '/usr/local/lib/fadelisk/knowledge',
            '/usr/lib/fadelisk/knowledge',
        ]
        for dir_ in possible_dirs:
            if exists(dir_):
                self.dirs.append(dir_)

    def get(self, name):
        for dir_ in self.dirs:
            filename = join(dir_, name) + '.yaml'
            if not exists(filename):
                continue
            with open(filename) as file_:
                return yaml.load(file_, Loader=YAMLLoader)
        raise KnowledgeNotFound('There is no knowledge of %s' % name)

