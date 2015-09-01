
import os
from mako.lookup import TemplateLookup

from .file_resource import FileResource
from .html_processor import HTMLProcessor
from .error_resource import NotFoundResource, InternalServerErrorResource

class Site(object):
    def __init__(self, path, site_conf, app, aliases=[]):
        self.path = path
        self.app = app
        self.conf = site_conf
        self._aliases = list(aliases)

        #-- Initialize Cache
        self.cache = {}
        self.request_data = {}
        self.initialize_cache()

        #-- Extract FQDN from directory base
        self.fqdn = os.path.basename(self.path)

        #-- Build resource tree from site directory structure
        self.resource = FileResource(self.rel_path('content'))

        self.resource.indexNames=app.conf['directory_index']
        self.resource.processors = {
            '.html': self.html_processor_factory,
            '.htm': self.html_processor_factory,
        }

        #-- "Lift" some subdirectories above content dir to keep them separate
        for directory in self.conf.get('top_level_directories', []):
            self.resource.putChild(directory,
                FileResource(self.rel_path(directory)))

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
            self.app.conf.get('template_directories', [])
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

    def get_template(self, path):
        return self.template_lookup.get_template(path)

    def initialize_cache(self):
        self.cache.clear()
        self.cache.update({
            'db': {},
            'conf': {},
            'file': {},
            'data': {},
        })

    def initialize_request_data(self):
        # Clear data before request (preserve ref)
        self.request_data.clear()
        self.request_data.update({
            #-- For delivering media of other types, like image/png. Just
            #   pack up your data payload and request.setHeader your
            #   content type.
            'payload': None,

            #-- Forms require unique field IDs. This will be incremented by
            #   templates which lay out input elements.
            'unique_field_id': 0,

            #-- Flags: Entries in this dictionary can be used to arbitrarily
            #   alter rendering behavior in site templates.
            'flag': {},

            #-- Debug messages: Strings added to this list may be formatted
            #   later to ask as informational output during development.
            'debug': [],

            #-- Extra Content: These can be used by a top-level site layout
            #   template to allow inheriting pages to add additional content.
            #   To use these, your top-level template must capture next.body
            #   before emitting the document head.
            'extra_local_fonts': [],
            'extra_google_fonts': [],
            'extra_stylesheets': [],
            'extra_screen_stylesheets': [],
            'extra_print_stylesheets': [],
            'extra_scripts': [],
            'extra_head_content': [],
        })

    def reset_request_context(self):
        self.initialize_request_data()          # every request
        if self.conf.get('debug'):
            self.initialize_cache()             # only in debug, preserve ref

    def get_aliases(self):
        return self._aliases

    def add_alias(self, alias):
        self._aliases.append(alias)

    def rel_path(self, path=None):
        if path:
            return os.path.join(self.path, path)
        return self.path

    def html_processor_factory(self, request_path, registry):
        return HTMLProcessor(request_path, registry, self)

