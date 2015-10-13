
<%def name="clean_path(path=None)"
    filter="n,trim">
    <%
        # TODO: Handle empty path nodes
        # TODO: handle '..' in nodes

        if isinstance(path, list):
            return [clean_path(p) for p in path]

        if path == None:
            return request.path

        if '#' in path:                             # Strip fragment
            path = path.split('#')[0]
        if '?' in path:                             # Strip query
            path = path.split('?')[0]
        if not path.endswith('/'):                  # Remove document portion
            path = path.rsplit('/', 1)[0] + '/'
        if not path.startswith('/'):                # Relative
            path = request.path + path

        return path
    %>
</%def>

<%def name="is_current_path(path)"
    filter="n,trim">
    <%
        return clean_path(path) == request.path
    %>
</%def>

<%def name="traversed_paths(path=None)"
    filter="n,trim">
    <%
        path = clean_path(path)
        nodes = path.split('/')

        traversed = []
        for i in range(1, len(nodes)):
            traversed.append('/'.join(nodes[:i]) + '/')

        return traversed
    %>
</%def>

