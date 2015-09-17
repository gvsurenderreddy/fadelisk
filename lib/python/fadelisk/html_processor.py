
from mako import exceptions
from twisted.web import resource

from .error_resource import BadRequestResource

class HTMLProcessor(resource.Resource):
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

        path = request.path
        if path.endswith('/'):
            path += 'index.html'

        try:
            self.site.render_context.reset()
            template = self.site.get_template(path)
            content = template.render(site=self.site, request=request,
                                      **self.site.render_context.get())
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

