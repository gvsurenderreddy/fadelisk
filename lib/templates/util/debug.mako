
<%!
    import traceback
    import pprint
%>

<%def name="append(message)">
    <%
        if not active():
            return ''

        if not 'debug' in request_data:
            request_data['debug'] = []

        request_data['debug'].append(message)
    %>
</%def>

<%def name="append_traceback(exc=None)">
    <%
        if not exc:
            return ''

        append('* EXCEPTION: %s' % str(exc))
        append(traceback.format_exc())
    %>
</%def>

<%def name="active()">
    <%
        return bool(site.conf.get('debug'));
    %>
</%def>

<%def name="display()">
    <%
        if not active()
            return ''
        messages = request_data.get('debug', [])
        if not messages:
            return ''
    %>
    <div id="debug-console">
        % for message in messages:
            <pre>${message|trim,h}</pre>
        % endfor
    </div>
</%def>

<%def name="pretty_print(something)">
    <%
        if not active()
            return ''

        pp = pprint.PrettyPrinter(indent=2, width=240)
        append(pp.pformat(something))
    %>
</%def>

