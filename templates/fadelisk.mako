##<%namespace name="menu" file="/example_global.mako" inheritable="True" />

<%!
    # import fadelisk
%>

<%
    request_data.update({
        #-- For delivering media of other types, like image/png. Just pack up
        # your data payload and request.setHeader your content type.
        'payload' : None,

        #-- Forms require unique field IDs. This will be incremented by
        #   templates which lay out input elements.
        'unique_field_id': 0,

        #-- Flags: Entries in this dictionary can be used to arbitrarily
        #   alter rendering behavior in site templates.
        'flag': {},

        #-- Debug messages: Strings added to this list may be formatted
        #   later to ask as informational output during development.
        'debug': [],
    })

    try:
        content = capture(next.body)
    except Exception as exc:
        # In debug mode, let twisted-web show its own traceback...
        if site.conf.get('debug'):
            raise
        # ...otherwise replace with a more-polite, less-informative message.
        last_resort_layout()
        return

    context.write(content)
    return
%>

<%def name="last_resort_layout()">
    <%
        # Set status to Internal Server Error
        request.setResponseCode(500)
    %>
    <html>
        <head>
            <title>Internal Server Error</title>
        </head>
        <body>
            <h1>Internal Server Error</h1>
            The web server has experienced an internal error, and
            cannot fulfill your request. We apologize for any
            inconvenience this may cause.
        </body>
    </html>
</%def>

