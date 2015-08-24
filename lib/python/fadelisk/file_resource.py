
from twisted.web import resource, static

class FileResource(static.File):
    def __init__(self, path, *args, **kwargs):
        static.File.__init__(self, path, *args, **kwargs)
        self.path = path

    def directoryListing(self):
        return resource.ForbiddenResource(
            "You are not allowed to list the contents of this directory.")
        # TODO: determine which dirs have been marked listable.
        # for allowed_dir in self.site_conf.get('allow_directory_listing', []):
        #     if self.path == allowed_dir.rstrip('/'):
        #         return static.DirectoryLister(self.path, self.listNames(),
        #                                       self.contentTypes,
        #                                       self.contentEncodings,
        #                                       self.defaultType)

