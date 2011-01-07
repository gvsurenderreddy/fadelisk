<%!
    import os
    import fadelisk
    leave_lower = 'and of the or with by to a nor because'.split()
%>

<%def name="page_title(uri=None)">
<%
    if 'page_title' not in cache['data']:       # Assure data cache
        cache['data']['page_title'] = {}

    if 'page_title' not in cache['conf']:       # Try to cache conf
        page_title_file_name = os.sep.join(
            [context['vhost_path'], 'etc', 'page_title.yaml'])
        try:
            cache['conf']['page_title'] = fadelisk.conf.ConfYAML(
                page_title_file_name)
        except:
            pass

    if not uri:                                 # Fetch path if none specified.
        uri = request.path

    if not uri.startswith('/'):
        uri = request.path + uri

    if not uri == '/':
        uri = uri.split('?')[0]                         # Remove query
        nodes = uri.split('/')
        if not uri.endswith('/'):                       # Snub document portion.
            nodes[-1] = ''
        uri = '/'.join(nodes)

    try:
        return cache['conf']['page_title'][uri]         # Try conf fetch
    except KeyError:
        pass
    try:
        return cache['data']['page_title'][uri]         # Try cache fetch
    except KeyError:
        pass

    if uri == '/':
        title = 'Home'
    else:
        title_words = []
        for tok in nodes[-2].split('_'):
            if title_words and tok in leave_lower: # Not first token/stays lower
                title_words.append(tok)
            else:
                title_words.append(tok.capitalize())
        title = ' '.join(title_words)

    cache['data']['page_title'][uri] = title
    return title
%>
</%def>

<%def name="path_title(uri=None)">
    <%
    if not uri:                                 # Fetch path if none specified.
        uri = request.path

    if not uri.startswith('/'):
        uri = request.path + uri

    if uri == '/':
        return []

    if not uri == '/':
        uri = uri.split('?')[0]                         # Remove query
        nodes = uri.split('/')[1:-1]

        _path_title = []
        _path = ['']
        for node in nodes:
            _path.append(node)
            _path_title.append(page_title('/'.join(_path+[''])))

        return _path_title
    %>
</%def>

## vim:ft=mako

