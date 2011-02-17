
<%namespace name="menu" file="/layout/menu.mako" />
<%namespace name="formula" file="/form/formula.mako" />
<%namespace name="redirect" file="/util/redirect.mako" inheritable="True" />

<%namespace name="auth" file="/packages/telegraph/auth.mako" />
<%namespace name="display" file="/packages/telegraph/display.mako" />
<%namespace name="database" file="/packages/telegraph/database.mako"/>

<%!
    import datetime
    from pymongo import errors

    menu_items = [
        { 'uri': './',              'states': 'noauth,user,admin' },
        { 'uri': '?action=list',    'states': 'noauth,user,admin' },
    ]
    menu_override = {
        './':                   'Recent Entries',
        '?action=list':         'List Entries',
        '?action=new':          'New Entry',
        '?action=login':        'Log In',
        '?action=links':        'Links',
        '?action=users':        'Users',
        '?action=logout':       'Log Out',
    }
%>

<%def name="app()">
    <%
        init();
        submenu();
        dispatch();
    %>
</%def>

<%def name="init()">
    <%
        request_data['telegraph'] = {}          # Establish/clear local store
        try:
            database.db_connect()
        except errors.AutoReconnect:
            return                              # Error handled by db_connect()

        auth.check_auth()
    %>
</%def>

<%def name="new_dispatch()">
    <%
        if not 'action' in request.args:
            display_most_recent()

        if not request.args['action'] in menu_items:
            redirect.refresh('./')

        # Dispatch
    %>
</%def>

<%def name="submenu()">
    <%
        override = {
            './': 'Recent Entries',
            '?action=list': 'List Entries',
            '?action=new': 'New Entry',
            '?action=login': 'Log In',
            '?action=links': 'Links',
            '?action=users': 'Users',
            '?action=logout': 'Log Out',
        }
        items = ['./', '?action=list']
        indicators = []
        if auth.state() != 'noauth':
            indicators = [
                database.get_user_full_name(
                    request_data['telegraph']['user']
                )
            ]
            items.extend([ '?action=new', '?action=logout' ])
            if auth.state_is_admin():
                items[-1:-1] = [ '?action=links', '?action=users' ]
        else:
            items = [ '?action=login' ]

        if not len(items):
            return
    %>
    <div class="submenu">
        ${menu.simple(items, override, indicators)}
    </div>
</%def>

<%def name="dispatch()">
    <%
        if 'id' in request.args:
            entry_id = request.args['id'][0]
            actions = {
                'view': entry_view,
                'edit': entry_edit,
                'delete': entry_delete,
            }
            requested_action = 'view'
            if 'action' in request.args:
                requested_action = request.args['action'][0]
            if requested_action in actions:
                actions[requested_action](entry_id)
                return
            else:
                redirect.refresh('./')
        else:
            actions = {
                'login': auth.login,
                'logout': auth.logout,
                'list': entry_list,
                'new': entry_new,
            }

            if 'action' in request.args:
                requested_action = request.args['action'][0]
                if requested_action in actions:
                    actions[requested_action]()
                    return
                else:
                    redirect.refresh('./')

        display.recent()
    %>
</%def>

<%def name="entry_list()">
    <%
        request_data['path_nodes'].append('List Entries')
        entries = database.fetch_entries()

        if not entries:
            context.write('No entries are available.')
            return
    %>

    <table class="spreadsheet" style="width: 99%; margin: 10pt auto;">
        <thead>
            % if auth.state_is_admin():
                <td>Visible</td>
            % endif
            <td>Time</td>
            <td class="highlight">Title</td>
            <td>Author</td>
        </thead>

        <tbody>
            % for entry in entries:
                <tr>
                    % if auth.state_is_admin():
                        <td class="center">
                            % if entry.get('visible'):
                              <span style="color: #1e1">&bull;</span>
                            % else:
                              <span style="color: #e11">&bull;</span>
                            % endif
                        </td>
                    % endif
                    <td>
                        ${entry.get('timestamp', 'Unstuck in Time')}
                    </td>
                    <td class="highlight">
                        <a href="?id=${entry['_id']}">${entry.get('title', '')}</a>
                    </td>
                    <td>
                        <%
                            entry_author = entry.get('author')
                        %>
                        % if entry_author:
                            ${database.get_user_full_name(auth.get_user(entry_author))}
                        % endif
                    </td>
                </tr>
            % endfor
        </tbody>
        <tfoot>
            % if auth.state_is_admin():
                <td></td>
            % endif
            <td></td>
            <td colspan="2">
                ${request_data['telegraph']['db']['entries'].count()} Entries
            </td>
        </tfoot>
        </table>
</%def>

<%def name="entry_view(entry_id)">
    <%
        entry = database.get_entry(entry_id)

        if not entry:
            context.write('<h1>No Such Entry</h1>')
            context.write('An entry with that ID does not exist.')
            # Entry ID Doesn't exist.
            return

        # Allow if visible to all
        if entry.get('visible'):
            request_data['path_nodes'].append('View Entry')
            display.entry_full(entry)
            return

        # Allow if user has admin privs, or user is author.
        if 'user' in request_data['telegraph']:
            user = request_data['telegraph']['user']
            if user.get('admin') or user['user_name'] == entry.get('author'):
                request_data['path_nodes'].append('View Entry')
                display.entry_full(entry)
                return

        # Adminish about authorship (or admin privs, but leave that out) 
        # being necessary.
        request_data['path_nodes'].append('Error')
        context.write('<h1>Entry Not visible.</h1>')
        context.write('You need to be logged in as the author to see this entry.')
    %>
</%def>

<%def name="entry_edit(entry_id)">
    <%
        if auth.need_login('You must be logged in to edit entries.'):
            return

        request_data['path_nodes'].append('Edit Entry')
        #:: ANY method
        entry = database.get_entry(entry_id)

        if not entry:
            no_such_entry()
            return

        if not auth.user_can_edit_entry(entry):
            error('To edit this entry, you must be its author '
                    + 'or have admin privileges.',
                title='Permission Denied')
            return

        #:: GET method
        if request.method == 'GET':
            entry_form(entry)
            return

        #:: POST method
        if request.method == 'POST':
            #process_entry()
            updated_entry = {
                '_id': entry['_id'],
                'timestamp': entry['timestamp'],
                'author': entry.get('author', ''),
                'visible': bool(formula.get_value('visible',attribute=False))
            }
            for field in 'title text'.split():
                updated_entry.update(
                    { field: formula.get_value(field, attribute=False) }
                )
            updated_entry.update(
                { 'visible': bool(formula.get_value('visible',attribute=False))}
            )
            tags = formula.get_value('tags',attribute=False).split(',')
            updated_entry.update(
                { 'tags': [tag.strip() for tag in tags] }
            )
            request_data['telegraph']['db']['entries'].save(updated_entry)
            request_data['path_nodes'].append('Success')
            context.write('<p>The entry has been updated.</p>')
            #entry_form(entry)
            return

    %>
</%def>

<%def name="entry_delete(entry_id)">
    <%def name="confirm()">
        <%
            request_data['path_nodes'].append('Confirm')
        %>
        <h1>Really Delete this entry?</h1>
        <a href="${request.uri}&confirm=yes">Delete</a>
        ## TODO: Return to previous page
        <a href="./">Cancel</a>
    </%def>
    <%
        request_data['path_nodes'].append('Delete Entry')

        if auth.state() == 'noauth':
            error('To delete this entry, you must log in.',
                title='Not Authenticated')
            return

        entry = database.get_entry(
            entry_id,
            error_on_noexist=True
        )
        if not entry:
            return

        if not auth.user_can_edit_entry(entry):
            error('To delete this entry, you must be its author '
                    + 'or have admin privileges.',
                title='Permission Denied')
            return

        if not formula.get_value('confirm', attribute=False):
            confirm()
            return

        try:
            request_data['telegraph']['db']['entries'].remove(
                {'_id': entry['_id']}
            )
        except:
            request_data['path_nodes'].append('Error')
        else:
            request_data['path_nodes'].append('Success')
    %>
</%def>

<%def name="entry_new()">
    <%
        if not 'user' in request_data['telegraph']:
            login_form(message='You must be logged in to create a new entry.')
            return
    %>
    <%
        if request.method == 'GET':
            request_data['path_nodes'].append('New Entry')
            entry_form({'visible': True})
            return

        if request.method == 'POST':
            #-- Process form here
            new_entry = {
                'timestamp': datetime.datetime.today().strftime(
                    "%Y-%m-%dT%H:%M:%S"
                ),
                'author': request_data['telegraph']['user']['user_name'],
                'visible': bool(formula.get_value('visible',attribute=False))
            }
            for field in 'title text'.split():
                new_entry.update(
                    { field: formula.get_value(field, attribute=False) }
                )
            new_entry.update(
                { 'visible': bool(formula.get_value('visible',attribute=False))}
            )
            tags = formula.get_value('tags',attribute=False).split(',')
            new_entry.update(
                { 'tags': [tag.strip() for tag in tags] }
            )

            request_data['telegraph']['db']['entries'].insert(new_entry)
            context.write('<h1>Entry added.</h1>')
            context.write('You have successfully created a new entry.')
            return
    %>
</%def>

<%def name="entry_form(entry={}, message='', highlight={})">
    <%
        entry_cols = "timestamp author title text visible".split()
        for col in entry_cols:
            entry.setdefault(col, '')
        tags = ', '.join(entry.get('tags', []))
        entry.update({ 'tags': tags })

        entryform = [
            [
                ['Title'],
                {'name': 'title', 'size': 64, 'maxlength': 1024 },
            ],
            [
                ['Entry Text'],
                {'name': 'text', 'element_type': 'textarea'},
            ],
            [
                ['Tags'],
                {'name': 'tags', 'size': 64, 'maxlength': 1024 },
            ],
            [
                ['Visibility'],
                {'name':'visible', 'element_type':'checkbox', 'label':'Visible'}
            ],
        ]
    %>
    ${formula.formula(fields=entryform, values=entry)}
</%def>

<%def name="error(message='', title='Error', add_path_node='Error')">
    <%
        request_data['path_nodes'].append(add_path_node)
    %>
    <h1>${title}</h1>
    <p>${message}</p>
</%def>


<%def name="no_such_entry()">
    <h1>That Entry Does Not Exist</h1>
    No entry was found with that identifier.
</%def>

