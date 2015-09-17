
from twisted.web import http

from .error import ErrorResource

class DocumentNotFoundResource(ErrorResource):
    def __init__(self, site):
        ErrorResource.__init__(self, site,
                               site.conf.get('error_page_404',
                                             '/errors/404_not_found.html'),
                               http.NOT_FOUND,
                               'Document Not Found',
                              'The document you requested could not be found.')
