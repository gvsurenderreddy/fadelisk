
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
            return self.site.render_path(self.path, request)
        except Exception as exc:
            self.site.app.log.error(exc)
            return self.error_content.get()


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

