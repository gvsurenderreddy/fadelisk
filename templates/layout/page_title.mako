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

<%def name="path_nodes(uri=None)">
    <%
        if not uri:                             # Fetch path if none specified.
            uri = request.path
        if uri == '/':                          # Special case: Home
            return []
        if not uri.startswith('/'):             # Absolutize relative paths
            uri = request.path + uri

        uri = uri.split('?')[0]                 # Remove query
        nodes = uri.split('/')[1:-1]            # N.B.: Also prunes document

        _path = '/'
        _path_nodes = []
        for node in nodes:
            _path += '%s/' % node               # go top to bottom
            _path_nodes.append([_path])         # add, leave title unresolved

        return _path_nodes
    %>
</%def>

<%def name="path(nodes=None, separator=' / ', links=True)">
    <%
        if not nodes:
            nodes = path_nodes()

        # Nodes in a path node list come in three types:
        # * String/Unicode: Just add the text without a link
        # * Two-element list: Contains a URI and a title.
        # * Single-member list: URI only. Title will be computed automatically.
        _path = []
        for node in nodes:
            if type(node) == str or type(node) == unicode:
                _path.append(node)
            if type(node) != list:
                continue
            if not len(node):
                continue
            if len(node) < 2:
                node.append(page_title(node[0]))
            if links:
                _path.append('<a href="%s">%s</a>' % (node[0], node[1]))
            else:
                _path.append(node[1])

        return separator.join(_path)
    %>
</%def>

<%def name="path_title(uri=None, separator=' / ', links=True)">
    <%
        if not uri:                         # Fetch path if none specified.
            uri = request.path

        if not uri.startswith('/'):
            uri = request.path + uri

        if uri == '/':
            return []

        uri = uri.split('?')[0]                         # Remove query
        nodes = uri.split('/')[1:-1]

        _path_title = []
        _path = '/'
        for node in nodes:
            _path += '%s/' % node
            _page_title = page_title(_path)
            if links:
                _path_title.append('<a href="%s">%s</a>' % (_path,_page_title))
            else:
                _path_title.append(_page_title)

        return separator.join(_path_title)
    %>
</%def>

## vim:ft=mako

