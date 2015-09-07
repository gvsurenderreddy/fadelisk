
import os
from twisted.web import resource, static
from .error_resource import NotFoundResource

class FileResource(static.File):
    def __init__(self, path, site):
        static.File.__init__(self, path)
        self.path = path
        self.site = site

        self.not_found_resource = NotFoundResource(self.site)

    def createSimilarFile(self, path):
        f = self.__class__(path, self.site)
        f.processors = self.processors
        f.indexNames = self.indexNames[:]
        f.childNotFound = self.childNotFound
        return f

    def directoryListing(self):
        for allowed_dir in self.site.conf.get('allow_directory_listing', []):
            dir_ = os.path.join(self.site.rel_path('content'),
                                     allowed_dir.strip('/'))
            dir_len = len(dir_)
            if (self.path == dir_ or
                (len(self.path) > dir_len and self.path[dir_len] == '/')):
                return static.DirectoryLister(self.path, self.listNames(),
                                              self.contentTypes,
                                              self.contentEncodings,
                                              self.defaultType)
        return self.not_found_resource

