
from twisted.web import http

from .error import ErrorResource

class BadRequestResource(ErrorResource):
    def __init__(self, site):
        ErrorResource.__init__(self, site,
                               site.conf.get('error_page_400',
                                             '/errors/400_bad_request.html'),
                               http.BAD_REQUEST, 'Bad Request',
                              'Your request could not be understood by the ' +
                               'server')
