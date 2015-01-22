
##:::( Document Head )::::::::::::::::::::::::::::::::::::::::::::::::::::::##

<%def name="stylesheets()">
    <%
        stylesheets = list(site.conf.get('stylesheets', []))
        stylesheets.extend(request_data.get('extra_stylesheets', []))
        screen_stylesheets = site.conf.get('screen_stylesheets', [])
        print_stylesheets = site.conf.get('print_stylesheets', [])
    %>
    % for stylesheet in stylesheets:
        <link rel="stylesheet" href="${stylesheet}" />
    % endfor
    % for stylesheet in screen_stylesheets:
        <link rel="stylesheet" media="screen" href="${stylesheet}" />
    % endfor
    % for stylesheet in print_stylesheets:
        <link rel="stylesheet" media="print" href="${stylesheet}" />
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
            return ""
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

<%def name="google_fonts()">
    % for font in site.conf.get('google_fonts', []):
        <link  href="http://fonts.googleapis.com/css?family=${font.replace(' ', '+')}" rel="stylesheet" type="text/css" />
    % endfor
</%def>


<%def name="rss_feed(uri='/rss/', title='RSS Feed')">
    <link rel="alternate"
        type="application/rss+xml"
        title="${title}"
        href="${uri}"
    /> 
</%def>

<%def name="resolve_organization_name()">
    <%
        org_name = site.conf.get('organization_name', {'short': "", 'long': ""})
        org_name.setdefault('short', "")
        org_name.setdefault('long', "")
        request_data['org_name'] = org_name
    %>
</%def>


