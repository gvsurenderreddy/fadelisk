<%!
    from fadelisk.conf import ConfYAML
    leave_lower = 'a an the and but or for nor on at to from by'.split()
%>

<%def name="page_title(path=None)">
    <%
        path = clean_path(path)

        # Try to load page title configuration into cache
        if 'page_title' not in cache['conf']:
            try:
                cache['conf']['page_title'] = ConfYAML(
                    site.rel_path('conf', 'page_title.yaml'))
            except:
                pass

        # Attempt to fetch title from cached configuration
        try:
            return cache['conf']['page_title'][path]
        except:
            pass

        # Root is "Home" by default unless configured otherwise.
        if path == '/':
            return 'Home'

        # Attempt to fetch from cache
        try:
            return cache['data']['page_title'][path]
        except:
            pass

        # Construct page title
        title_words = []
        for word in path.split('/')[-2].split('_'):
            if not word:                                # Empty path node
                continue
            if title_words and word in leave_lower:
                title_words.append(word)
            else:
                title_words.append(word.capitalize())
        title = ' '.join(title_words)

        # Ensure page title cache structure, and add title
        if 'page_title' not in cache['data']:
            cache['data']['page_title'] = {}
        cache['data']['page_title'][path] = title

        return title
    %>
</%def>

<%def name="breadcrumb_title(path=None, separator=' &rarr; ', links=True)">
    <%
        traversed = traversed_paths(path)
        titles = [page_title(p) for p in traversed[1:]]

        return separator.join(titles)
    %>
</%def>

<%def name="breadcrumbs(traversed=None, path=None,
            separator=' / ', links=True)">
    <%
        if not traversed:
            traversed = traversed_paths(path)

        trail = []
        for place in traversed:
            if not place.beginswith('/'):
                trail.append(place)
                continue
            if links:
                trail.append('<a href="%s">%s</a>' %
                             (place, page_title(place)))
            else:
                trail.append(page_title(place))

        return separator.join(trail)
    %>
</%def>

<%def name="traversed_paths(path=None)">
    <%
        path = clean_path(path)
        nodes = path.split('/')

        traversed = []
        for i in range(1, len(nodes)):
            traversed.append('/'.join(nodes[:i]) + '/')

        return traversed
    %>
</%def>

<%def name="organization_name(size='long')">
    <%
        try:
            return site.conf['organization_name'][size]
        except KeyError:
            return None
    %>
</%def>

<%def name="clean_path(path=None)">
    <%
        if path == None:
            return request.path

        if '?' in path:                                 # Contains query
            path = path.split('?')[0]
        if not path.startswith('/'):                    # Might be relative
            path = request.path + path

        # TODO: Handle empty path nodes
        # TODO: handle '..' in nodes

        if not path.endswith('/'):
            path = path.rsplit('/', 1)[0] + '/'         # Clip document portion

        return path
    %>
</%def>

<%def name="is_current_path(path)">
    <%
        path = clean_path(path)
        return path == request.path
    %>
</%def>
