## <%page cached="False" cache_timeout="15" cache_type="memory"/>
<%namespace file="/util/cookie.mako" import="cookie_set, cookie_crumble"/>
<%namespace name="debug" file="/util/debug.mako" />
<%namespace name="menu" file="/layout/menu.mako" />
<%namespace name="form" file="/form/form.mako" />
<%namespace name="formula" file="/form/formula.mako" />
<%namespace name="redirect" file="/util/redirect.mako" inheritable="True" />

<%!
    import os
    import csv
    import datetime
    import urllib
    import hashlib
    import pprint

    from pymongo import Connection, ASCENDING, DESCENDING
    try:
        from pymongo import bson
    except ImportError:
        import bson
%>

<%def name="telegraph()">
    <%
        db_connect()
        check_auth()
        content = capture(dispatch)
        submenu()
        context.write(content)
    %>
</%def>


##:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: DISPATCHER

<%def name="dispatch()">
    <%
        if 'id' in request.args:
            entry_id = request.args['id'][0]
            actions = {
                'view': entry_view,
                'edit': entry_edit,
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
                'login': login,
                'logout': logout,
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

        display_most_recent()
    %>
</%def>

##::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: MAJOR MODES

<%def name="entry_list()">
    <%
        request_data['path_title'].append('List Entries')
        entries = fetch_entries()

        if not entries:
            context.write('No entries are available.')
            return
    %>

    <table class="spreadsheet" style="margin: 10pt auto;">
        <thead>
            % if request_data['telegraph']['user']:
                <td>Visible</td>
            % endif
            <td>Time</td>
            <td class="highlight">Title</td>
            <td>Author</td>
        </thead>

        <tbody>
            % for entry in entries:
                <tr>
                    <td class="center">
                        % if entry.get('visible'):
                          <span style="color: #1e1">&bull;</span>
                        % else:
                          <span style="color: #e11">&bull;</span>
                        % endif
                    </td>
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
                            ${get_user_full_name(get_user(entry_author))}
                        % endif
                    </td>
                </tr>
            % endfor
        </tbody>
        <tfoot>
            <td></td>
            <td></td>
            <td colspan="2">${request_data['telegraph']['db']['entries'].count()} Entries</td>
        </tfoot>
        </table>

</%def>

<%def name="fetch_entries()">
<%
    if 'user' in request_data['telegraph']:
        if request_data['telegraph']['user'].get('admin'):
            # Admin: All articles
            query = None
        else:
            # User: All articles either visible or author matches user_name
            query = {
                '$or': [
                    {'visible': True},
                    {'author': request_data['telegraph']['user']['user_name'] }
                ]
            }
    else:
        # Not Logged In: Only visible articles.
        query = { 'visible': True }

    return request_data['telegraph']['db']['entries'].find(
        query,
        sort=[('timestamp', DESCENDING)]
    )
%>
</%def>

<%def name="display_most_recent()">
<%
    request_data['path_title'].append('Recent Entries')
    entries = fetch_entries()

    if not entries:
        context.write('No entries are available.')
        return

    for entry in entries[0:4]:
        display_entry(entry)
%>
</%def>

<%def name="display_entry(entry)">
    <%
        # Time
        entry_time = "Unstuck in Time"
        if 'timestamp' in entry:
            timestamp = datetime.datetime.strptime(
            entry['timestamp'],
                "%Y-%m-%dT%H:%M:%S"
            )
            entry_time = ' '.join([
                timestamp.strftime('%A,'),
                str(timestamp.day),
                timestamp.strftime('%B %Y &mdash; %I:%M %p'),
            ])

        # Author
        author = []
        author_full_name = 'Lost+Found'
        if 'author' in entry:
            author = get_user(entry['author'])
            if author:
                author_full_name = author.get('full_name', 'Lost+Found')

        # Toolbar
        editable = False
        if 'user' in request_data['telegraph']:
            user = request_data['telegraph']['user']
            if (user.get('admin') or
                user['user_name'] == author.get('user_name')):
                editable = True

    %>
    <article id="${entry['_id']}" class="telegraph">
        <p class="entrytitle">
            <a href="?id=${entry['_id']}">${entry['title']}<span>[permalink]</span></a>
        </p>
        <p class="header left">${author_full_name}</p>
        <p class="header right">${entry_time}</p>
        % if editable:
            <div class="toolbar">
                <%
                    override = {
                    '?action=edit&id=%s' % entry['_id']: 'Edit',
                    }
                    menu.simple(override.keys(), override)
                %>
            </div>
        % endif
        <div class="entrybody">${entry['text']}</div>
    </article>
</%def>

<%def name="entry_view(entry_id)">
    <%
        entry = get_entry(entry_id)

        if not entry:
            context.write('<h1>No Such Entry</h1>')
            context.write('An entry with that ID does not exist.')
            # Entry ID Doesn't exist.
            return

        # Allow if visible to all
        if entry.get('visible'):
            display_entry(entry)
            return

        # Allow if user has admin privs, or user is author.
        if 'user' in request_data['telegraph']:
            user = request_data['telegraph']['user']
            if user.get('admin') or user['user_name'] == entry.get('author'):
                display_entry(entry)
                return

        # Adminish about authorship (or admin privs, but leave that out) 
        # being necessary.
        context.write('<h1>Entry Not visible.</h1>')
        context.write('You need to be logged in as the author to see this entry.')
    %>
</%def>

<%def name="need_login(message=None)">
    <%
        if 'user' in request_data['telegraph']:
            return False

        login_form(message or 'You must be logged in to perform this action.')
        return True
    %>
</%def>

<%def name="entry_edit(entry_id)">
    <%
        if need_login('You must be logged in to edit entries.'):
            return

        #:: ANY method
        entry = get_entry(entry_id)

        if not entry:
            no_such_entry()
            return

        if not user_can_edit_entry(entry):
            context.write('<h1>You cannot edit this article.</h1>')
            context.write('You must be its author, or have admin privileges.')
            return

        #:: GET method
        if request.method == 'GET':
            context.write('<h1>Edit Entry</h1>')
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
            context.write('<h1>Entry updated.</h1>')
            context.write('The entry has been updated to reflect the new data.')
            #entry_form(entry)
            return

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
            request_data['path_title'].append('New Entry')
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

##::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: LAYOUT ::::

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
        if 'user' in request_data['telegraph']:
            indicators = [
                get_user_full_name(request_data['telegraph']['user'])
            ]
            items.extend([ '?action=new', '?action=logout' ])
            if request_data['telegraph']['user'].get('admin'):
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

<%def name="display_entry(entry)">
    <%
        # Time
        entry_time = "Unstuck in Time"
        try:
            if 'timestamp' in entry:
                timestamp = datetime.datetime.strptime(
                entry['timestamp'],
                    "%Y-%m-%dT%H:%M:%S"
                )
                entry_time = ' '.join([
                    timestamp.strftime('%A,'),
                    str(timestamp.day),
                    timestamp.strftime('%B %Y &mdash; %I:%M %p'),
                ])
        except:
            pass

        # Author
        author_descr = get_user_full_name(get_user(entry['author']))

        # Toolbar
        editable = False
        if 'user' in request_data['telegraph']:
            user = request_data['telegraph']['user']
            if (user.get('admin') or
                user['user_name'] == author.get('user_name')):
                editable = True

    %>
    <article id="${entry['_id']}" class="telegraph">
        <p class="entrytitle">
            <a href="?id=${entry['_id']}">${entry['title']}
                <span>[permalink]</span></a>
        </p>
        <p class="header left">${author_descr|h}</p>
        <p class="header right">${entry_time}</p>
        % if editable:
            <div class="toolbar">
                <%
                    override = {
                    '?action=edit&id=%s' % entry['_id']: 'Edit',
                    }
                    menu.simple(override.keys(), override)
                %>
            </div>
        % endif
        <div class="entrybody">${entry.get('text')|trim}</div>
        <p class="tags">${', '.join(entry.get('tags', []))}</p>
    </article>
</%def>

<%def name="get_user(user_name)">
    <%
        return request_data['telegraph']['db']['users'].find_one({'user_name': user_name})
    %>
</%def>

<%def name="get_entry(entry_id)">
    <%
        return request_data['telegraph']['db']['entries'].find_one({'_id': bson.ObjectId(entry_id)})
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


<%def name="no_such_entry()">
    <h1>That Entry Does Not Exist</h1>
    No entry was found with that identifier.
</%def>

## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - Authentication

<%def name="login_form(message='', goal='')">
    <%
        request_data['path_title'].append('Log In')
        request_data['telegraph']['submenu'] = []
        true_goal = (form.get_value('goal', attribute=False) or
            goal or request.uri)
    %>
    <p class="critical-message">${message}</p>
    <form action="?action=login" method=post>
        <label for="user_name">User Name:</label><br />
        <input type="text" name="user_name" ${form.get_value('user_name')} maxlength="32" size="12"/><br />
        <label for="password">Password:</label><br />
        <input type="password" name="password" value='' maxlength="12" size="12"/><br />
        <input name="goal" type="hidden" value="${true_goal}" />

        <input class="submit" type="submit" value="Submit" />
    </form>
</%def>

<%def name="login()">
    <%def name="login_success()">
        <%
            request_data['path_title'].append('Log In')
            request_data['path_title'].append('Success')
        %>
        <h1>Logged In</h1>
        You have been successfully logged in.
    </%def>
    <%
        if 'auth_token' in request_data['telegraph']:
            redirect.redirect('./')
            return

        if request.method == 'GET':
            login_form(goal=request.getHeader('referer'))
            return

        if not request.method == 'POST':
            redirect.refresh('./')
            return

        form_user = request.args['user_name'][0]
        form_password = request.args['password'][0]

        user = request_data['telegraph']['db']['users'].find_one({'user_name': form_user})

        if not user:
            login_form(message="Login unsuccessful. Please retry.")
            return

        if not form_password == user['password']:
            login_form(message='Login unsuccessful. Please retry.')
            return

        sha256 = hashlib.new('sha256')
        sha256.update(''.join([
            form_user,
            user['password'],
            site.conf['secret']
        ]))
        request_data['telegraph']['auth_token'] = sha256.hexdigest()

        request.addCookie('user_name', form_user)
        request.addCookie('auth_token', request_data['telegraph']['auth_token'])
        login_success()
        goal = request.args['goal'][0]
        redirect.refresh(goal)
    %>
</%def>

<%def name="logout()">
You have been successfully logged out.
<%
    request_data['path_title'].append('Log Out')
    cookie_crumble('user_name')
    cookie_crumble('auth_token')
    redirect.refresh('./')
%>
</%def>

<%def name="check_auth()">
    <%doc>
        If logged in, be sure that auth_token hasn't been tampered with.
    </%doc>
    <%
        #-- If possible, fetch the auth tokens from stored cookies.
        user_name = request.getCookie('user_name')
        auth_token = request.getCookie('auth_token')

        #-- No authentication information?
        if not user_name:
            # Auth token doesn't make sense without user name; clear it.
            if auth_token:
                cookie_crumble('auth_token')
            return
            # NO AUTH

        #-- No authentication token? (Leave user_name if set.) 
        if not auth_token:
            debug.append("AUTH: No auth token.")
            return
            # NO AUTH

        #-- Verify against user list.
        user = get_user(user_name)

        #-- Remove both cookies if user not found.
        if not user:
            debug.append('AUTH: User %s not in DB.' % user_name)
            cookie_crumble('user_name')
            cookie_crumble('auth_token')
            return

        #-- Build auth_token hash
        sha256 = hashlib.new('sha256')
        sha256.update(''.join([
            user_name,
            user['password'],
            site.conf['secret']
        ]))
        hashed_auth = sha256.hexdigest()

        #-- Verify against DB. Remove cookies if no match.
        if not auth_token == hashed_auth:
            debug.append('AUTH: Auth token not matched for user %s.'% user_name)
            cookie_crumble('user_name')
            cookie_crumble('auth_token')
            return
            # NO AUTH

        #-- SUCCESS

        # Ensure an admin bit, basing it on the user_name if necessary.
        user.setdefault('admin', (username == 'admin'))

        #-- Cache data.
        request_data['telegraph']['user'] = user
        request_data['telegraph']['auth_token'] = auth_token
    %>
</%def>

<%def name="user_can_edit_entry(entry)">
    <%
        if not entry:
            return False

        if not 'user' in request_data['telegraph']:
            return False

        if entry.get('author') == request_data['telegraph']['user']['user_name']:
            return True

        if request_data['telegraph']['user']['admin']:
            return True
    %>
</%def>

<%def name="db_connect()">
    <%
        connection = Connection(
            site.conf['telegraph']['host'],
            site.conf['telegraph']['port']
        )
        db = connection[site.conf['telegraph']['db']]

        request_data['telegraph'] = {
            'db': db
        }
    %>
</%def>

<%def name="pretty_print(something)">
    <%
        pp = pprint.PrettyPrinter(indent=4)
        debug.append(pp.pformat(something))
    %>
</%def>

## vim:ft=mako

