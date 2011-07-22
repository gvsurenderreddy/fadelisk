
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

<%def name="display()">
    <%
        if not 'debug' in request_data:
            return ''
        if not site.conf['debug']:
            return ''

#        debug_strings = []
#        for item in request_data['debug']:
#            try:
#                debug_strings.append("<p>%s</p>\n" % str(item))
#            except:
#                pass
#        debug_concat = ''.join(debug_strings)
#
#        #if not debug_concat:
#        #    return
    %>
    <div id="debug-console">
        % for message in request_data['debug']:
            <p>${message |h,trim}</p>
        % endfor
    </div>
</%def>

<%def name="pretty_print(something)">
    <%
        pp = pprint.PrettyPrinter(indent=4)
        append(pp.pformat(something))
    %>
</%def>

