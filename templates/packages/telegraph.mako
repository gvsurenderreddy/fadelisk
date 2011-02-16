<%doc>
    This is the Telegraph main application. You may call it directly using:

        <%include file="/packages/telegraph.mako" />

    For slightly higher performance, you can import its namespace
    by placing at the top of your template or page:

        <%namespace name="telegraph" file="/packages/telegraph.mako" />

    and then later executing the app with

        ${telegraph.app()}

    or

        <%
            telegraph.app()
        %>

    Other methods are available for various types of displays such as sidebar
    listings, extract listings, and syndications. See display.mako for
    details on calling these procedures from your templates.
</%doc>

<%namespace name="telegraph_app" file="/packages/telegraph/app.mako" />

<%
    #-- For direct inclusion:
    app()
%>

<%def name="app()">
    <%
        #-- For an API-style namespace call:
        telegraph_app.app()
    %>
</%def>

## vim:ft=mako

