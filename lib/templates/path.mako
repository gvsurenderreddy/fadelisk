
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

<%def name="clean_paths(paths=[])">
    <%
        return [clean_path(path) for path in paths]
    %>
</%def>

<%def name="is_current_path(path)">
    <%
        return clean_path(path) == request.path
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

