
##:::( Document Head )::::::::::::::::::::::::::::::::::::::::::::::::::::::##

<%def name="stylesheets()">
    <%
        stylesheets = list(site.conf.get('stylesheets', []))
        stylesheets.extend(request_data.get('extra_stylesheets', []))
    %>
    % for stylesheet in stylesheets:
        <link rel="stylesheet" href="${stylesheet}" />
    % endfor
</%def>

<%def name="scripts()">
    <%
        scripts = list(site.conf.get('scripts', []))
        scripts.extend(request_data.get('extra_scripts', []))
    %>
    % for script in scripts:
            <script src="${script}"></script>
    % endfor
</%def>

<%def name="local_fonts(fonts_base_uri='/fonts')">
    <%
        fonts = list(site.conf.get('local_fonts', []))
        fonts.extend(request_data.get('extra_local_fonts', []))
        if not fonts:
            return
    %>
    <style type="text/css">
    % for font in fonts:
    @font-face {
        font-family: '${font}';
        font-style: normal;
        font-weight: normal;
        src: local('${font}'),
             url('${fonts_base_uri}/${font}.woff') format('woff');
    }
    % endfor
    </style>
</%def>

<%def name="rss_feed(uri='/rss/', title='RSS Feed')">
    <link rel="alternate"
        type="application/rss+xml"
        title="${title}"
        href="${uri}"
    /> 
</%def>


