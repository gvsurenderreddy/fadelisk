
import os
from twisted.web import resource, static

class FileResource(static.File):
    def __init__(self, path, site):
        static.File.__init__(self, path)
        self.path = path
        self.site = site

    def createSimilarFile(self, path):
        f = self.__class__(path, self.site)
        f.processors = self.processors
        f.indexNames = self.indexNames[:]
        f.childNotFound = self.childNotFound
        return f

    def directoryListing(self):
        for allowed_dir in self.site.conf.get('allow_directory_listing', []):
            test_path = os.path.join(
                self.site.rel_path('content'),
                allowed_dir.strip('/'))
            if self.path == test_path:
                return static.DirectoryLister(self.path, self.listNames(),
                                              self.contentTypes,
                                              self.contentEncodings,
                                              self.defaultType)
        return resource.ForbiddenResource(
            "You are not allowed to list the contents of this directory.")

