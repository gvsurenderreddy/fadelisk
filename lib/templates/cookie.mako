
<%def name="cookie_set(name, value, expires=None, domain=None, path=None,
                       max_age=None, comment=None, secure=None)"
    filter="n,trim">
    <%
        request.addCookie(name, value, expires=expires, domain=domain,
            path=path, max_age=max_age, comment=comment, secure=secure)
    %>
</%def>


<%def name="cookie_crumble(name)"
    filter="n,trim">
    <%
        cookie_set(name, '',
            # Cookie dates are formatted "%a, %d-%b-%Y %H:%M:%S GMT"
            expires='Sat, 14-Feb-1970 00:00:00 GMT')
    %>
</%def>


