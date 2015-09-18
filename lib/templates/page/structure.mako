<%namespace name="page_info" file="/page/info.mako" />
<%namespace name="menu" file="/menu.mako" />

##:::( Document )::::::::::::::::::::::::::::::::::::::::::::::::::::::::::##

<%def name="html5_document()">
    <!DOCTYPE html>
    <html lang="en">
        ${caller.body()}
    </html>
</%def>

##:::( Major Sections )::::::::::::::::::::::::::::::::::::::::::::::::::::##

<%def name="head()">
    ${'<head>'}
        <meta charset="utf-8" />
        <link rel="icon" href="/images/favicon.png" type="image/png" />
        <title>
            ${': '.join([page_info.organization_name(),
                page_info.breadcrumb_title()])}
        </title>
            ${stylesheets()}
            ${local_fonts()}
            ${google_fonts()}
            ${scripts()}
            ${rss_feed()}
    ${'</head>'}
</%def>

<%def name="nav(items=[], overrides={})">
    <nav>
        ${menu.ul(items=items, overrides=overrides)}
    </nav>
</%def>

##:::( Subsections for HEAD )::::::::::::::::::::::::::::::::::::::::::::::##

<%def name="stylesheets()">
    <%
        stylesheets = list(site.conf.get('stylesheets', []))
        stylesheets.extend(request_data.get('extra_stylesheets', []))

        screen_stylesheets = list(site.conf.get('screen_stylesheets', []))
        screen_stylesheets.extend(request_data.get(
            'extra_screen_stylesheets', []))

        print_stylesheets = list(site.conf.get('print_stylesheets', []))
        print_stylesheets.extend(request_data.get(
            'extra_print_stylesheets', []))
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
        <link href="http://fonts.googleapis.com/css?family=${font.replace(' ', '+')}" rel="stylesheet" type="text/css" />
    % endfor
</%def>

<%def name="rss_feed(uri='/rss/', title='RSS Feed')">
    <link rel="alternate" type="application/rss+xml" title="${title}"
        href="${uri}" /> 
</%def>

