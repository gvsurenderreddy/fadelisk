
<%namespace file="/util/cookie.mako" import="cookie_set, cookie_crumble"/>
<%namespace name="form" file="/form/form.mako" />
<%namespace name="redirect" file="/util/redirect.mako" />

<%!
    import hashlib
%>

<%def name="check_auth()">
    <%doc>
        Determine auth state.
    </%doc>
    <%
        # Fetch telegraph data struct for neatness.
        telegraph_data = request_data['telegraph']

        telegraph_data['auth_state'] = 'noauth'

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
            debug.debug_append("AUTH: No auth token.")
            return
            # NO AUTH

        #-- Verify against user list.
        user = get_user(user_name)

        #-- Remove both cookies if user not found.
        if not user:
            debug.debug_append('AUTH: User %s not in DB.' % user_name)
            cookie_crumble('user_name')
            cookie_crumble('auth_token')
            return
            # NO AUTH

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
            debug.debug_append('AUTH: Auth token not matched for user %s.'% user_name)
            cookie_crumble('user_name')
            cookie_crumble('auth_token')
            return
            # NO AUTH

        #-- SUCCESS

        # Cache data.
        telegraph_data['user'] = user
        telegraph_data['auth_token'] = auth_token
        telegraph_data['auth_state'] = 'user'

        # Promote the auth state if user has admin privileges.
        if user['user_name'] == 'admin' or user.get('admin', False):
            telegraph_data['auth_state'] = 'admin'
    %>
</%def>

<%def name="user_can_edit_entry(entry)">
    <%
        if state_is_admin():         # Admin: can edit everything
            return True

        if state() == 'user':        # User: can edit his own entries
            if user('user_name') == entry.get('author'):
                return True

        return False                    # Not logged in: can't edit anything
    %>
</%def>

<%def name="user(column=None)">
    <%
        try:
            user = request_data['telegraph']['user']
            if column:
                return user.get(column)
            return user
        except KeyError:
            return None
    %>
</%def>

<%def name="state()">
    <%
        return request_data['telegraph'].get('auth_state', 'noauth')
    %>
</%def>

<%def name="state_is_admin()">
    <%
        return state() == 'admin'
    %>
</%def>

<%def name="login()">
    <%def name="login_success()">
        <%
            request_data['path_nodes'].append('Log In')
            request_data['path_nodes'].append('Success')
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
    request_data['path_nodes'].append('Log Out')
    cookie_crumble('user_name')
    cookie_crumble('auth_token')
    redirect.refresh('./')
%>
</%def>

<%def name="login_form(message='', goal='')">
    <%
        request_data['path_nodes'].append('Log In')
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

<%def name="need_login(message=None)">
    <%
        if state() != 'noauth':
            return False

        login_form(message or 'You must be logged in to perform this action.')
        return True
    %>
</%def>

<%def name="get_user(user_name)">
    <%
        return request_data['telegraph']['db']['users'].find_one(
            {'user_name': user_name}
        )
    %>
</%def>

