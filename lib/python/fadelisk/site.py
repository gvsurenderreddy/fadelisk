#!/usr/bin/env python

import sys
import os
from twisted.web import resource, static, script
from mako.lookup import TemplateLookup
from mako import exceptions

class SneakyStatic(static.File):
    def __init__(self, path, defaultType="text/html", ignoredExts=(),
                 registry=None, allowExt=0):
        static.File.__init__(self, path, defaultType, ignoredExts,
                             registry, allowExt)

#    def getChild(self, path, request):
#        raise OSError

class ProcessorHTML(resource.Resource):
    isLeaf = True
    allowedMethods = ('GET', 'POST', 'HEAD')

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
#        for charm, target in self.site.conf['charm'].iteritems():
#            if path.startswith(charm):
#                path = target or charm
#                break
#        with open("/tmp/path.txt", "w") as f:
#            data = f.write(path)
        if path.endswith('/'):
            path = ''.join([path, 'index.html'])
        template = self.site.template_lookup.get_template(path)

        return template.render(
            request=request,
            request_data={},
            site=self.site,
            site_path=self.site.path,
            **self.site.template_context
        )


class ErrorResource(resource.Resource):
    isLeaf = True

    def __init__(self, site, path):
        resource.Resource.__init__(self)
        self.site = site
        self.path = path

    def render_GET(self, request):
        request.setHeader('server', self.site.application_conf['server'])
        request.setResponseCode(404)

        if self.path.endswith('/'):
            self.path = ''.join([self.path, 'index.html'])
        template = self.site.template_lookup.get_template(self.path)
        return template.render(
            request=request,
            request_data={},
            site=self.site,
            site_path=self.site.path,
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

        #self.resource = static.File(self.rel_path('content'))
        self.resource = SneakyStatic(self.rel_path('content'))
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
            output_encoding='utf-8',
            filesystem_checks = True,
        )

    def rel_path(self, path=None):
        if path:
            return os.path.join(self.path, path)
        return self.path

    def factory_processor_html(self, request_path, registry):
        return ProcessorHTML(request_path, registry, self)

