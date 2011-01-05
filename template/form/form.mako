
<%def name="get_value(name, value='', attribute=True, offset=0)">
<%
    if name in request.args:
        value = request.args[name][offset]

    if attribute:
        return 'value="%s"' % value             # For form markup.
    return value                                # For general use.
%>
</%def>

## vim:ft=mako
