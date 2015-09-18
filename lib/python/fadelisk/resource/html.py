
from mako import exceptions
from twisted.web import resource

from .bad_request import BadRequestResource

class HTMLResource(resource.Resource):
    isLeaf = True
    allowedMethods = ('GET', 'POST', 'HEAD')

    def __init__(self, path, registry, site):
        self.path = path
        self.registry = registry
        self.site = site

        resource.Resource.__init__(self)

    def render(self, request):
        if request.method not in self.__class__.allowedMethods:
            return BadRequestResource().render()

        if '//' in request.path:
            path = request.path
            while '//'  in path:
                path = path.replace('//', '/')
            request.setHeader('location', path)
            request.setResponseCode(301)
            return ''

        try:
            content = self.site.render_request(request)
        except Exception as exc:
            self.site.app.log.error(exc)
            request.setResponseCode(500)
            if self.site.conf.get('debug'):
                return exceptions.html_error_template().render()
            else:
                return self.site.internal_server_error_resource.render(request)

        payload = self.site.render_context.get_request_data()['payload']
        if payload != None:
            return payload

        return content

