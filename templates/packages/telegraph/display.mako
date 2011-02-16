
<%namespace name="menu" file="/layout/menu.mako" />
<%namespace name="telegraph_auth" file="/packages/telegraph/auth.mako" />
<%namespace name="telegraph_database" file="/packages/telegraph/database.mako"/>

<%!
    import datetime
%>

<%def name="entry_full(entry)">
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
            author = telegraph_auth.get_user(entry['author'])
            if author:
                author_full_name = author.get('full_name', 'Lost+Found')
    %>
    <article id="${entry['_id']}" class="telegraph">
        <p class="entrytitle">
            <a href="?id=${entry['_id']}">${entry['title']}<span>[permalink]</span></a>
        </p>
        <p class="header left">${author_full_name}</p>
        <p class="header right">${entry_time}</p>
        % if telegraph_auth.user_can_edit_entry(entry):
            <div class="toolbar">
                <%
                    override = {
                        '?action=edit&id=%s' % entry['_id']: 'Edit',
                        '?action=delete&id=%s' % entry['_id']: 'Delete',
                    }
                    menu.simple(
                        [
                            '?action=edit&id=%s' % entry['_id'],
                            '?action=delete&id=%s' % entry['_id'],
                        ]
                    , override)
                %>
            </div>
        % endif
        <div class="entrybody">${entry['text']}</div>
    </article>
</%def>

<%def name="recent()">
<%
    request_data['path_nodes'].append('Recent Entries')
    entries = telegraph_database.fetch_entries()

    if not entries:
        context.write('No entries are available.')
        return

    for entry in entries[0:4]:
        entry_full(entry)
%>
</%def>

