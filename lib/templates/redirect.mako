
<%def name="redirect(location, status=301)">
<%
    request.setHeader('location', location)
    request.setResponseCode(status)
%>
</%def>

<%def name="refresh(url='', timeout=0)">
<%
    request.setHeader('Refresh', '%s; url=%s' % (timeout, url))
%>
</%def>

