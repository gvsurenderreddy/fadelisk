
from twisted.web import http

from .error import ErrorResource

class InternalServerErrorResource(ErrorResource):
    def __init__(self, site):
        ErrorResource.__init__(self, site,
                               site.conf.get('error_page_500',
                                     '/errors/500_internal_server_error.html'),
                               http.INTERNAL_SERVER_ERROR,
                               'Internal Server Error',
                              'The server could not fulfill your request.')

