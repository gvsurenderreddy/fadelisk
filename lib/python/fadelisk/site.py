#!/usr/bin/env python

import sys
import os
from twisted.web import resource, static, script
from mako.lookup import TemplateLookup
from mako import exceptions

class ProcessorHTML(resource.Resource):
    isLeaf = True
    allowedMethods = ('GET', 'POST', 'HEAD')

    def __init__(self, path, registry, site):
        resource.Resource.__init__(self)
        self.path = path
        self.registry = registry
        self.site = site

    def render_GET(self, request):
        request.setHeader('server', 'fadelisk 1.0 (barndt)')
        request.setResponseCode(200)

        path = request.path
        if path.endswith('/'):
            path = ''.join([path, 'index.html'])
        template = self.site.template_lookup.get_template(path)
        return template.render(
            request=request,
            request_data={},
            site_conf=self.site.conf,
            **self.site.template_context
        )

    def render_POST(self, request):
        request.setHeader('server', 'fadelisk 1.0 (barndt)')
        request.setResponseCode(200)

        path = request.path
        if path.endswith('/'):
            path = ''.join([path, 'index.html'])
        template = self.site.template_lookup.get_template(path)
        return template.render(
            request=request,
            request_data={},
            site_conf=self.site.conf,
            **self.site.template_context
        )

class ErrorResource(resource.Resource):
    isLeaf = True

    def __init__(self, site, path):
        resource.Resource.__init__(self)
        self.site = site
        self.path = path

    def render_GET(self, request):
        request.setHeader('server', 'fadelisk 1.0 (barndt)')
        request.setResponseCode(404)

        if self.path.endswith('/'):
            self.path = ''.join([self.path, 'index.html'])
        template = self.site.template_lookup.get_template(self.path)
        return template.render(
            request=request,
            request_data={},
            **self.site.template_context
        )

class Site(object):
    def __init__(self, path, application_conf, site_conf):
        self.path = path
        self.application_conf = application_conf
        self.conf = site_conf

        self.error_resource = ErrorResource(self, '/errors/404_not_found.html')
        #self.error_resource.processors = {'.html': self.factory_processor_html}
        #self.error_resource.childNotFound = resource.NoResource("NO RESOURCE")

        self.resource = static.File(self.rel_path('content'))
        self.resource.indexNames=['index.html', 'index.rpy']
        self.resource.processors = {
            '.html': self.factory_processor_html,
            '.rpy': script.ResourceScript
        }
        self.resource.childNotFound = self.error_resource

        # "Lift" some subdirectories above content dir to keep them separate
        if self.conf['top_level_directories']:
            for directory in self.conf['top_level_directories']:
                self.resource.putChild(directory,
                                       static.File(self.rel_path(directory)))

        self.template_context = {
            'vhost_path': self.path,
            'environ': os.environ,
            'cache': {
                'conf': {},
                'file': {},
                'data': {},
            },
        }
        self.template_lookup = TemplateLookup(
            directories = [
                self.rel_path('content'),
                self.rel_path('template'),
                '/srv/project/fadelisk/template',
            ],
            module_directory = self.rel_path('tmp/mako-module'),
            input_encoding='utf-8',
            filesystem_checks = True,
        )

    def rel_path(self, path=None):
        if path:
            return os.path.join(self.path, path)
        return self.path

    def factory_processor_html(self, request_path, registry):
        return ProcessorHTML(request_path, registry, self)

