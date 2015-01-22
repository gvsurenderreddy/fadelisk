
<%!
    import traceback
    import pprint
%>

<%def name="append(message)">
    <%
        if not 'debug' in request_data:
            request_data['debug'] = []
        if not site.conf['debug']:
            return

        request_data['debug'].append(message)
    %>
</%def>

<%def name="append_traceback(exc=None)">
    <%
        if exc:
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
        if not site.conf.get('debug'):
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
        pp = pprint.PrettyPrinter(indent=2, width=240)
        append(pp.pformat(something))
    %>
</%def>

