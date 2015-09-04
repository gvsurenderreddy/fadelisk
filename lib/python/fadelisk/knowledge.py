
from os.path import dirname, exists, join, realpath
import yaml
from .conf import ConfYAML

class KnowledgeNotFound(Exception): pass

class Knowledge(object):
    def __init__(self, site):
        self.site = site

        self.dirs = []
        possible_dirs = [
            self.library_rel_path('knowledge'),
            site.rel_path('/lib/knowledge'),
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
                return yaml.load(file_, Loader=yaml.CLoader)
        raise KnowledgeNotFound('There is no knowledge of %s' % name)

    def library_rel_path(self, name):
        my_path = dirname(realpath(__file__))
        library_dir = dirname(dirname(my_path))
        return join(library_dir, name)

