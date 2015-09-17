
from twisted.web import http

from .error import ErrorResource

class ForbiddenResource(ErrorResource):
    def __init__(self, site):
        ErrorResource.__init__(self, site,
                               site.conf.get('error_page_403',
                                             '/errors/403_forbidden.html'),
                               http.FORBIDDEN, 'Forbidden',
                               'You do not have access to the document ' +
                               'you requested.')
