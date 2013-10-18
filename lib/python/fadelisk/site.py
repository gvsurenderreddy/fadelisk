
import sys
import os
from twisted.web import resource, static
from mako.lookup import TemplateLookup
from mako import exceptions

class Site(object):
    def __init__(self, path, application_conf, site_conf, aliases=None):
        self.path = path
        self.application_conf = application_conf
        self.conf = site_conf
        if isinstance(aliases, list):
            self._aliases = aliases
        else:
            self._aliases = []

        self.data = {}
        self.fqdn = os.path.basename(self.path)

        self.error_resource = ErrorResource(self, '/errors/404_not_found.html')
        #self.error_resource.processors = {'.html': self.factory_processor_html}
        #self.error_resource.childNotFound = resource.NoResource("NO RESOURCE")

        self.resource = static.File(self.rel_path('content'))
        #self.resource = SneakyStatic(self.rel_path('content'))
        self.resource.indexNames=['index.html', 'index.htm']
        self.resource.processors = {'.html': self.factory_processor_html}
        self.resource.childNotFound = self.error_resource

        # "Lift" some subdirectories above content dir to keep them separate
        for directory in self.conf.get('top_level_directories', []):
            self.resource.putChild(
                directory,
                static.File(self.rel_path(directory))
            )

        self.template_context = {
            #'vhost_path': self.path,
            'cache': {
                'db': {},
                'conf': {},
                'file': {},
                'data': {},
            },
        }
        template_lookup_directories = [
            self.rel_path('content'),
            self.rel_path('templates'),
            self.rel_path('template'),
        ]
        template_lookup_directories.extend(
            self.application_conf.get('template_directories', [])
        )
        self.template_lookup = TemplateLookup(
            directories = template_lookup_directories,
            module_directory = self.rel_path('tmp/mako-module'),
            input_encoding='utf-8',
            output_encoding='utf-8',
            filesystem_checks = True,
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

class SneakyStatic(static.File):
    def __init__(self, path, defaultType="text/html", ignoredExts=(),
                 registry=None, allowExt=0):
        static.File.__init__(self, path, defaultType, ignoredExts,
                             registry, allowExt)

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
                The web server has encountered an internal server error and is 
                unable to fulfill your request
            </p>
        </body>
    </html>
    """

    def __init__(self, path, registry, site):
        resource.Resource.__init__(self)
        self.path = path
        self.registry = registry
        self.site = site

    def render_GET(self, request):
        return self.render_request(request)

    def render_POST(self, request):
        return self.render_request(request)

    def render_request(self, request):
        request.setHeader('server', self.site.application_conf['server'])
        request.setResponseCode(200)

        path = request.path
        if path.endswith('/'):
            path += 'index.html'

        request_data = {}
        try:
            template = self.site.template_lookup.get_template(path)
            content = template.render(
                request=request,
                request_data=request_data,
                site_data=self.site.data,
                site=self.site,
                **self.site.template_context
            )
            #request.setHeader('Content-Type', 'text/plain')
            return request_data.get('payload', None) or content
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

        template = self.site.template_lookup.get_template(self.path)
        return template.render(
            request=request,
            request_data={},
            site_data=self.site.data,
            site=self.site,
            **self.site.template_context
        )


