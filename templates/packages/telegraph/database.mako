
<%namespace name="auth" file="/packages/telegraph/auth.mako" />

<%!
    from pymongo import Connection, ASCENDING, DESCENDING, errors
    try:
        from pymongo import bson
    except ImportError:
        import bson
%>


<%def name="db_connect()">
    <%def name="connect_error()">
        <%
            request_data['path_nodes'].append('Offline')
        %>
        <h1>This area of the site is currently offline.</h1>
        Please try again soon.
    </%def>
    <%
        try:
            connection = Connection(
                site.conf['telegraph']['host'],
                site.conf['telegraph']['port']
            )
        except errors.AutoReconnect as e:
            connect_error()
            raise

        db = connection[site.conf['telegraph']['db']]
        request_data['telegraph']['db'] = db
    %>
</%def>


<%def name="get_entry(entry_id, error_on_noexist=False)">
    <%
        entry = request_data['telegraph']['db']['entries'].find_one({'_id': bson.ObjectId(entry_id)})
        if error_on_noexist and not entry:
            error("An entry with that ID could not be found.",
                title='Entry Does Not Exist')
        return entry
    %>
</%def>

<%def name="get_user_full_name(user)">
    <%
        if not user:
            return 'Lost+Found'

        return user.get(
            'full_name',                # try to get full name
            user['user_name']           # fall back on user_name
        )
    %>
</%def>

<%def name="fetch_entries()">
<%
    if auth.state() == 'admin':
        # Admin: All entries
        query = None
    elif auth.state() == 'user':
        # User: All entries either visible or author matches user_name
        query = {
            '$or': [
                {'visible': True},
                {'author': request_data['telegraph']['user']['user_name'] }
            ]
        }
    else:
        # Not Logged In: Only visible entries.
        query = { 'visible': True }

    return request_data['telegraph']['db']['entries'].find(
        query,
        sort=[('timestamp', DESCENDING)]
    )
%>
</%def>

