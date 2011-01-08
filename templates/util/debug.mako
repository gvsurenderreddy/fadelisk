
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

        debug_concat = '\n\n'.join(request_data['debug'])

        if not debug_concat:
            return
    %>
    <div id="debug">
        <p>DEBUG</p>
        <pre>${debug_concat |h,trim}</pre>
    </div>
</%def>


