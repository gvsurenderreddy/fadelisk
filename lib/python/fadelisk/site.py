
import sys
import os
from string import Template
from twisted.web import resource, static, error
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

        #-- Initialize Cache
        self.cache = {}
        self.request_data = {}
        self.initialize_cache()

        #-- Extract FQDN from directory base
        self.fqdn = os.path.basename(self.path)

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

        #-- Build Error resources
        self.not_found_resource = NotFoundResource(self)
        self.resource.childNotFound = self.not_found_resource

        self.internal_server_error_resource = InternalServerErrorResource(self)

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
        template_lookup_options = {
            'directories': self.template_lookup_directories,
            'cache_type': 'memory',
            #'cache_type': 'file',
            #'module_directory': self.rel_path('tmp/mako-module'),
            'input_encoding': 'utf-8',
            'output_encoding': 'utf-8',
            'encoding_errors': 'replace',
        }
        self.template_lookup = TemplateLookup(**template_lookup_options)

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

    def __init__(self, path, registry, site):
        resource.Resource.__init__(self)
        #self.path = path
        #self.registry = registry
        self.site = site

    #-- By default, twisted also calls render_GET for HEAD requests
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
        self.site.request_data.clear()          # every time, new ref
        if self.site.conf.get('debug'):
            self.site.initialize_cache()        # only in debug, preserve ref

        # Render the template
        try:
            template = self.site.template_lookup.get_template(path)
            content = template.render(site=self.site, request=request,
                                      request_data=self.site.request_data,
                                      cache=self.site.cache)
        except:
            request.setResponseCode(500)
            if self.site.conf.get('debug'):
                return exceptions.html_error_template().render()
            else:
                return self.site.internal_server_error_resource.render(request)

        return self.site.request_data.get('payload') or content


class ErrorResource(resource.Resource):
    isLeaf = True

    def __init__(self, site, path, response_code, fallback_title,
                 fallback_message):
        resource.Resource.__init__(self)
        self.site = site
        self.path = path
        self.response_code = response_code

        self.error_content = ErrorPageContent(fallback_title, fallback_message)

    def render(self, request):
        request.setHeader('server', self.site.application_conf['server'])
        request.setResponseCode(self.response_code)

        try:
            template = self.site.get_template_lookup().get_template(self.path)
            return template.render(site=self.site, request=request,
                                   request_data=self.site.request_data,
                                   cache=self.site.cache)
        except:
            return self.error_content.get()


class InternalServerErrorResource(ErrorResource):
    def __init__(self, site):
        ErrorResource.__init__(self, site,
                               '/errors/500_internal_server_error.html',
                               500, 'Internal Server Error',
                              'The server could not fulfill your request.')


class NotFoundResource(ErrorResource):
    def __init__(self, site):
        ErrorResource.__init__(self, site, '/errors/404_not_found.html',
                               404, 'Document Not Found',
                              'The document you requested could not be found.')


class ErrorPageContent(object):
    content= """
    <!DOCTYPE html>
    <html lang="en" class="error-page">
        <head>
            <meta charset="utf-8">
            <link rel="icon" href="/images/favicon.png" type="image/png">
            <title>$title</title>
        </head>
        <body>
            <h1>$title</h1>
            $message
        </body>
    </html>
    """

    def __init__(self, title, message):
        self.title = title
        self.message = message

        template = Template(self.content)
        self.document = template.safe_substitute(title=title, message=message)

    def get(self):
        return self.document

