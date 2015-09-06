
import os
from string import Template
from twisted.web import resource

class ErrorResource(resource.Resource):
    isLeaf = True

    def __init__(self, site, path, response_code, fallback_title,
                 fallback_message):
        resource.Resource.__init__(self)
        self.site = site
        self.path = path
        self.response_code = response_code

        self.error_content = ErrorPageContent(fallback_title, fallback_message)

    def render(self, request):
        request.setResponseCode(self.response_code)
        try:
            self.site.reset_request_context()
            template = self.site.get_template(self.path)
            return template.render(site=self.site, request=request,
                                   request_data=self.site.request_data,
                                   cache=self.site.cache)
        except Exception as exc:
            self.site.app.log.error(exc)
            return self.error_content.get()


class InternalServerErrorResource(ErrorResource):
    def __init__(self, site):
        ErrorResource.__init__(self, site,
                               site.conf.get('error_page_500',
                                     '/errors/500_internal_server_error.html'),
                               500, 'Internal Server Error',
                              'The server could not fulfill your request.')


class NotFoundResource(ErrorResource):
    def __init__(self, site):
        ErrorResource.__init__(self, site,
                               site.conf.get('error_page_404',
                                             '/errors/404_not_found.html'),
                               404, 'Document Not Found',
                              'The document you requested could not be found.')


class BadRequestResource(ErrorResource):
    def __init__(self, site):
        ErrorResource.__init__(self, site,
                               site.conf.get('error_page_400',
                                             '/errors/400_bad_request.html'),
                               400, 'Bad Request',
                              'Your request could not be understood by the ' +
                               'server')


class ErrorPageContent(object):
    content= """
    <!DOCTYPE html>
    <html lang="en" class="error-page">
        <head>
            <meta charset="utf-8">
            <link rel="icon" href="/images/favicon.png" type="image/png">
            <title>$title</title>
        </head>
        <body>
            <h1>$title</h1>
            $message
        </body>
    </html>
    """

    def __init__(self, title, message):
        self.title = title
        self.message = message

        template = Template(self.content)
        self.document = template.safe_substitute(title=title, message=message)

    def get(self):
        return self.document

