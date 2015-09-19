
<%def name="organization_name(size='long')">
    <%
        try:
            return site.conf['organization_name'][size]
        except KeyError:
            return ''
    %>
</%def>

