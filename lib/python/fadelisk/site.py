
import sys
import os
from twisted.web import resource, static
from mako.lookup import TemplateLookup
from mako import exceptions

class ResourceSafeDirectory(static.File):
    def __init__(self, *args, **kwargs):
        static.File.__init__(self, *args, **kwargs)

    def directoryListing(self):
        return resource.ForbiddenResource(
            "You are not allowed to list the contents of this directory.")

# TODO: Needs site_conf to determine which dirs have been marked listable
# Data should be stored accessibly, perhaps in the registry.
#
# class ResourceSafeDirectory(static.File):
#     def __init__(self, path, defaultType="text/html", ignoredExts=(),
#                  registry=None, allowExt=0, site_conf={}):
#         self.site_conf = site_conf
#         static.File.__init__(self, path)
#
#     def directoryListing(self):
#         for allowed_dir in self.site_conf.get('allow_directory_listing', []):
#             if self.path == allowed_dir.rstrip('/'):
#                 return static.DirectoryLister(self.path, self.listNames(),
#                                               self.contentTypes,
#                                               self.contentEncodings,
#                                               self.defaultType)
#         return resource.ForbiddenResource(
#             "You are not allowed to list the contents of this directory.")

class Site(object):
    def __init__(self, path, application_conf, site_conf, aliases=[]):
        #-- Save args
        self.path = path
        self.application_conf = application_conf
        self.conf = site_conf
        self._aliases = list(aliases)

        #-- Extract FQDN from directory base
        self.fqdn = os.path.basename(self.path)

        #-- Initialize Cache
        self.cache = {}
        self.initialize_cache()

        #-- Build resource tree from site directory structure
        self.resource = ResourceSafeDirectory(path=self.rel_path('content'))

        self.resource.indexNames=['index.html', 'index.htm']
        self.resource.processors = {
            '.html': self.factory_processor_html,
            '.htm': self.factory_processor_html,
        }

        #-- "Lift" some subdirectories above content dir to keep them separate
        for directory in self.conf.get('top_level_directories', []):
            self.resource.putChild(directory,
                static.File(self.rel_path(directory)))

        #-- Build Error resource for not-found condition
        self.error_resource = ErrorResource(self, '/errors/404_not_found.html')
        #self.error_resource.processors = {'.html':self.factory_processor_html}
        #self.error_resource.childNotFound = resource.NoResource("NO RESOURCE")
        self.resource.childNotFound = self.error_resource

        #-- Build list of directories to use for template resolution
        self.template_lookup_directories = [
            self.rel_path('content'),
            self.rel_path('templates'),
            self.rel_path('template'),
        ]
        self.template_lookup_directories.extend(
            self.application_conf.get('template_directories', [])
        )

        #-- Create the template resolvers
        self.template_lookup_options = {
            'directories': self.template_lookup_directories,
            'module_directory': self.rel_path('tmp/mako-module'),
            'input_encoding': 'utf-8',
            'output_encoding': 'utf-8',
            'encoding_errors': 'replace',
        }
        self.template_lookup = TemplateLookup(**self.template_lookup_options)
        self.template_lookup_debug_mode = TemplateLookup(
            filesystem_checks = True, **self.template_lookup_options)

    def initialize_cache(self):
        self.cache.clear()
        self.cache.update(
            {
                'db': {},
                'conf': {},
                'file': {},
                'data': {},
            }
        )

    def get_aliases(self):
        return self._aliases

    def add_alias(self, alias):
        self._aliases.append(alias)

    def rel_path(self, path=None):
        if path:
            return os.path.join(self.path, path)
        return self.path

    def factory_processor_html(self, request_path, registry):
        return ProcessorHTML(request_path, registry, self)

class ProcessorHTML(resource.Resource):
    isLeaf = True
    allowedMethods = ('GET', 'POST', 'HEAD')
    internal_server_error = """
        <!doctype html>
        <html lang="en">
            <head>
                <meta charset="utf-8">
                <link rel="icon" href="/images/favicon.png" type="image/png">
                <title>Internal Server Error</title>
            </head>
            <body>
                <h1>Internal Server Error</h1>
                <p>
                    The web server has encountered an internal server error
                    and is unable to fulfill your request
                </p>
            </body>
        </html>
    """

    def __init__(self, path, registry, site):
        resource.Resource.__init__(self)
        #static.File.__init__(self, path, registry=registry)
        #self.path = path
        #self.registry = registry
        self.site = site

    #-- By default, twisted calls render_GET for HEAD requests
    #def render_HEAD(self, request):
    #    return self.render_request(request)

    def render_GET(self, request):
        return self.render_request(request)

    def render_POST(self, request):
        return self.render_request(request)

    def render_request(self, request):
        request.setHeader('server', self.site.application_conf['server'])

        path = request.path
        if path.endswith('/'):
            path += 'index.html'

        # Clear data before request
        request_data = {}                       # every time, new ref
        if self.site.conf.get('debug'):
            self.site.initialize_cache()        # only in debug, preserve ref

        # Render the template
        try:
            if self.site.conf.get('debug'):
                template_lookup = self.site.template_lookup_debug_mode
            else:
                template_lookup = self.site.template_lookup
            template = template_lookup.get_template(path)
            content = template.render(
                site=self.site,
                request=request,
                request_data=request_data,
                cache=self.site.cache,
            )
            return request_data.get('payload') or content
        except:
            request.setResponseCode(500)
            if self.site.conf.get('debug'):
                return exceptions.html_error_template().render()
            else:
                return ProcessorHTML.internal_server_error

class ErrorResource(resource.Resource):
    isLeaf = True

    def __init__(self, site, path):
        resource.Resource.__init__(self)
        self.site = site
        self.path = path
        if self.path.endswith('/'):
            self.path += 'index.html'

    def render_GET(self, request):
        request.setHeader('server', self.site.application_conf['server'])
        request.setResponseCode(404)

        if self.site.conf.get('debug'):
            template_lookup = self.site.template_lookup_debug_mode
        else:
            template_lookup = self.site.template_lookup
        template = template_lookup.get_template(self.path)
        return template.render(
            site=self.site,
            request=request,
            request_data={},
            cache=self.site.cache,
        )


