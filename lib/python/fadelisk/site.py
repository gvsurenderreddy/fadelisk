
import os
from mako.lookup import TemplateLookup

from .resource import                   \
        InternalServerErrorResource,    \
        NotFoundResource,               \
        FileResource,                   \
        HTMLResource
from .render_context import RenderContext
from .knowledge import Knowledge

class FadeliskSite(object):
    def __init__(self, path, site_conf, app):
        self.path = path
        self.app = app
        self.conf = site_conf

        self.aliases = []

        self.render_context = RenderContext(self)

        #-- Extract FQDN from directory base
        self.fqdn = os.path.basename(self.path)

        #-- Build resource tree from site directory structure
        self.resource = FileResource(self.rel_path('content'), self)

        self.resource.indexNames = app.conf['directory_index']
        self.resource.processors = {
            '.html': self.html_resource_factory,
            '.htm': self.html_resource_factory,
        }

        #-- "Lift" some subdirectories above content dir to keep them separate
        for directory in self.conf.get('top_level_directories', []):
            self.resource.putChild(directory,
                FileResource(self.rel_path(directory), self))

        #-- Build Error resources
        self.not_found_resource = NotFoundResource(self)
        self.resource.childNotFound = self.not_found_resource
        self.internal_server_error_resource = InternalServerErrorResource(self)

        #-- Build list of directories to use for template resolution
        template_paths = [
            self.rel_path('content'),
            self.rel_path('templates'),
        ]
        template_paths.extend(
            self.app.conf.get('extra_template_directories', []))
        template_paths.extend([
            self.app.rel_path('lib', 'templates'),
            self.app.rel_path('lib', 'packages'),
            '/usr/local/lib/fadelisk/templates',
            '/usr/local/lib/fadelisk/packages',
            '/usr/lib/fadelisk/templates',
            '/usr/lib/fadelisk/packages',
        ])
        self.template_lookup_directories = []
        for template_path in template_paths:
            if os.path.exists(template_path):
                self.template_lookup_directories.append(template_path)

        #-- Create the template resolvers
        template_lookup_options = {
            'directories': self.template_lookup_directories,
            'cache_type': 'memory',
            #'cache_type': 'file',
            #'module_directory': self.rel_path('tmp', 'mako-module'),
            'input_encoding': 'utf-8',
            'output_encoding': 'utf-8',
            'encoding_errors': 'replace',
        }
        self.template_lookup = TemplateLookup(**template_lookup_options)

        self.knowledge = Knowledge(self)

    def rel_path(self, *nodes):
        if nodes:
            return os.path.join(self.path, *nodes)
        return self.path

    def html_resource_factory(self, request_path, registry):
        return HTMLResource(request_path, registry, self)

    def get_template(self, path):
        return self.template_lookup.get_template(path)

    def render_path(self, path, request):
        self.render_context.reset()
        template = self.get_template(path)
        return template.render(site=self, request=request,
                               **self.render_context.get())

    def render_request(self, request):
        path = request.path
        if path.endswith('/'):
            path += 'index.html'
        return self.render_path(path, request)

