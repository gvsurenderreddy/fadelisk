<%!
    from datetime import date
%>

<%def name="cookie_set(
    name,
    value,
    expires=None,
    domain=None,
    path=None,
    max_age=None,
    comment=None,
    secure=None
)">
    <%
        request.addCookie(
            name,
            value,
            expires=expires,
            domain=domain,
            path=path,
            max_age=max_age,
            comment=comment,
            secure=secure
        )
    %>
</%def>


<%def name="cookie_crumble(name)">
    <%
        cookie_set(
            name,
            '',
            expires=date(1970, 2, 14).strftime("%a, %d-%b-%Y %H:%M:%S GMT")
        )
    %>
</%def>


