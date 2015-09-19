
<%namespace name="path_utils" file="/path.mako" />

<%!
    from fadelisk.conf import ConfYAML
    leave_lower = 'a an the and but or for nor on at to from by'.split()
%>

<%def name="title(path=None)">
    <%
        path = path_utils.clean_path(path)

        # Try to load page title configuration into cache
        if 'title' not in cache['conf']:
            try:
                cache['conf']['title'] = ConfYAML(
                    site.rel_path('conf', 'title.yaml'))
            except:
                pass

        # Attempt to fetch title from cached configuration
        try:
            return cache['conf']['title'][path]
        except:
            pass

        # Root is "Home" by default unless configured otherwise.
        if path == '/':
            return 'Home'

        # Attempt to fetch from cache
        try:
            return cache['data']['title'][path]
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
        if 'title' not in cache['data']:
            cache['data']['title'] = {}
        cache['data']['title'][path] = title

        return title
    %>
</%def>

<%def name="breadcrumb_title(path=None, separator=' &rarr; ')">
    <%
        traversed = path_utils.traversed_paths(path)
        if len(traversed) == 1:
            return "Home"
        titles = [title(p) for p in traversed[1:]]

        return separator.join(titles)
    %>
</%def>

<%def name="breadcrumbs(traversed=None, path=None, separator=' / ')">
    <%
        if not path:
            path = request.path
        else:
            path = clean_path(path)

        if not traversed:
            traversed = path_utils.traversed_paths(path)

        trail = []
        for place in traversed:
            if not place.startswith('/'):
                trail.append(place)
                continue
            trail.append('<a href="%s">%s</a>' % (place, title(place)))

        return separator.join(trail)
    %>
</%def>

