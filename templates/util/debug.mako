
<%def name="debug_append(message)">
    <%
        if not 'debug' in request_data:
            return

        if not site.conf['debug']:
            return

        request_data['debug'].append(message)
    %>
</%def>

<%def name="debug_display()">
    <%
        if not 'debug' in request_data:
            return

        if not site.conf['debug']:
            return

        if not request_data['debug']:
            return

        debug_strings = []
        for item in request_data['debug']:
            try:
                debug_strings.append(str(item))
            except:
                pass
        debug_concat = '\n\n'.join(debug_strings)

        if not debug_concat:
            return
    %>
    <div id="debug">
        <p>DEBUG</p>
        <pre>${debug_concat |h,trim}</pre>
    </div>
</%def>


