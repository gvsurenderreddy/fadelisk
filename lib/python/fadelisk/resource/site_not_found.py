
from twisted.web import http, resource

class SiteNotFoundResource(resource.ErrorPage):
    def __init__(self, app):
        self.app = app

        resource.ErrorPage.__init__(self, http.FORBIDDEN, "No Such Site",
                          "Your request does not correspond to a known site.")

    def render(self, request):
        self.app.log.warning("Site not found for %s" %
                             request.getHeader('host') or '(unknown host)')
        return resource.ErrorPage.render(self, request)

