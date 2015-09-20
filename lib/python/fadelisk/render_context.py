
from copy import deepcopy

request_data_reset_values = {
    #-- For delivering media of other types, like image/png. Just
    #   pack up your data payload and request.setHeader your
    #   content type.
    'payload': None,

    #-- Forms require unique field IDs. This will be incremented by
    #   templates which lay out input elements.
    'unique_field_id': 0,

    #-- Flags: Entries in this dictionary can be used to arbitrarily
    #   alter rendering behavior in site templates.
    'flags': {},

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
}

cache_reset_values = {
    'db': {},
    'conf': {},
    'file': {},
    'data': {},
}

class RenderContext(object):
    def __init__(self, site):
        self.site = site

        self.__request_data = RequestData()
        self.__cache = Cache()

    def get_request_data(self):
        return self.__request_data

    def get_cache(self):
        return self.__cache

    def get(self):
        return {
            'request_data': self.__request_data,
            'cache': self.__cache,
        }

    def reset(self):
        self.__request_data.reset()     # every request
        if self.site.conf.get('debug'):
            self.__cache.reset()        # only in debug


class RequestContextMember(dict):
    def __init__(self, initial_values):
        self.initial_values = initial_values
        self.update(self.initial_values)

    def reset(self):
        self.clear()
        self.update(deepcopy(self.initial_values))


class RequestData(RequestContextMember):
    def __init__(self):
        RequestContextMember.__init__(self, request_data_reset_values)


class Cache(RequestContextMember):
    def __init__(self):
        RequestContextMember.__init__(self, cache_reset_values)


