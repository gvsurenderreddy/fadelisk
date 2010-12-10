<%!
    import re
    import os
    import fadelisk

    leave_lower = 'and of the or with by to a nor because'.split()
%>

<%def name="page_title(uri=None)">
<%

    if uri == None:
	uri = context.request_uri

    if not uri:
	return ''

    nodes = uri.split('/')[:]

    # Server would redirect (302) for a directory called with no trailing
    # slash, and would not-found (404) if a doc were called as a directory
    # (i.e., with a trailing slash). If the URI had no slash, it was a doc
    # and the last node can br pruned.
    if not uri.endswith('/'):
        nodes[-1] = ''

    if not nodes:
	return 'Home'

    try:
        #-- Data cache
        if not cache['data'].has_key('page_title'):
            cache['data']['page_title'] = {}
        #-- Conf cache
        if not cache['conf'].has_key('page_title'):
            page_title_file_name = os.sep.join(
                [context['vhost_path'], 'etc', 'page_title.yaml'])
            if os.access(page_title_file_name, os.F_OK):
                cache['conf']['page_title'] = fadelisk.conf.ConfYAML(
                    page_title_file_name)
    except:
        pass

    title_key = '/'.join(nodes)
    try:
        return cache['conf']['page_title'][title_key]
    except:
        pass
    try:
        return cache['data']['page_title'][title_key]
    except:
        pass

    title_words = []
    for tok in nodes[-2].split('_'):
        if title_words and tok in leave_lower:
            title_words.append(tok)
        else:
            title_words.append(tok.capitalize())
    title = ' '.join(title_words)

    try:
        cache['data']['page_title'][title_key] = title
    except:
        pass

    return title
%>
</%def>

## vim:ft=mako

