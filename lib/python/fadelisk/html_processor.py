
from twisted.web import resource

class HTMLProcessor(resource.Resource):
    isLeaf = True
    allowedMethods = ('GET', 'POST', 'HEAD')

    def __init__(self, path, registry, site):
        resource.Resource.__init__(self)
        self.path = path
        self.registry = registry
        self.site = site

    #-- By default, twisted also calls render_GET for HEAD requests
    def render_GET(self, request):
        return self.render_request(request)

    def render_POST(self, request):
        return self.render_request(request)

    def render_request(self, request):
        request.setHeader('server', self.site.application_conf['server'])

        path = request.path
        if path.endswith('/'):
            path += 'index.html'

        # Clear data before request (preserve ref)
        self.site.request_data.clear()
        self.site.request_data.update({
            #-- For delivering media of other types, like image/png. Just
            #   pack up your data payload and request.setHeader your
            #   content type.
            'payload': None,

            #-- Forms require unique field IDs. This will be incremented by
            #   templates which lay out input elements.
            'unique_field_id': 0,

            #-- Flags: Entries in this dictionary can be used to arbitrarily
            #   alter rendering behavior in site templates.
            'flag': {},

            #-- Debug messages: Strings added to this list may be formatted
            #   later to ask as informational output during development.
            'debug': [],

            #-- Extra Content: These can be used by a top-level site layout
            #   template to allow inheriting pages to add additional content.
            #   To use these, your top-level template must capture next.body
            #   before emitting the document head.
            'extra_local_fonts': [],
            'extra_google_fonts': [],
            'extra_stylesheets': [],
            'extra_screen_stylesheets': [],
            'extra_print_stylesheets': [],
            'extra_scripts': [],
            'extra_head_content': [],
        })
        if self.site.conf.get('debug'):
            self.site.initialize_cache()        # only in debug, preserve ref

        # Render the template
        try:
            template = self.site.template_lookup.get_template(path)
            content = template.render(site=self.site, request=request,
                                      request_data=self.site.request_data,
                                      cache=self.site.cache)
        except:
            request.setResponseCode(500)
            if self.site.conf.get('debug'):
                return exceptions.html_error_template().render()
            else:
                return self.site.internal_server_error_resource.render(request)

        payload = self.site.request_data.get('payload')
        if payload != None:
            return payload

        return content

