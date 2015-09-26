<%namespace name="title_utils" file="/title.mako" />
<%namespace name="organization" file="/organization.mako" />
<%namespace name="menu" file="/menu.mako" />

<%def name="head()">
    ${'<head>'}
        <meta charset="utf-8" />
        <link rel="icon" href="/images/favicon.png" type="image/png" />
        <title>
            ${': '.join([organization.organization_name(),
                title_utils.breadcrumb_title()])}
        </title>
        ${stylesheets()}
        ${local_fonts()}
        ${google_fonts()}
        ${scripts()}
        ${rss_feed()}
    ${'</head>'}
</%def>

<%def name="stylesheets_of_media(media='all')">
    <%
        main = 'stylesheets'
        if media != 'all':
            main = media + '_' + main
        extra = 'extra_' + main

        stylesheets = list(site.conf.get(main) or [])
        stylesheets.extend(request_data.get(extra) or [])
    %>
    % for stylesheet in stylesheets:
        <link rel="stylesheet" href="${stylesheet}" />
    % endfor
</%def>

<%def name="stylesheets()">
    ${stylesheets_of_type('all')}
    ${stylesheets_of_type('screen')}
    ${stylesheets_of_type('print')}
</%def>

<%def name="scripts()">
    <%
        scripts = list(site.conf.get('scripts') or [])
        scripts.extend(request_data.get('extra_scripts') or [])
    %>
    % for script in scripts:
        <script src="${script}"></script>
    % endfor
</%def>

<%def name="local_fonts(uri='/fonts')">
    <%
        fonts = list(site.conf.get('local_fonts') or [])
        fonts.extend(request_data.get('extra_local_fonts') or [])
        if not fonts:
            return ''
    %>
    <style type="text/css">
        % for font in fonts:
            @font-face {
                font-family: '${font}';
                font-style: normal;
                font-weight: normal;
                src: local('${font}'),
                     url('${uri}/${font}.woff') format('woff');
            }
        % endfor
    </style>
</%def>

<%def name="google_fonts(uri='http://fonts.googleapis.com/css?family=')">
    % for font in site.conf.get('google_fonts', []):
        <link href="${uri}${font.replace(' ', '+')}" rel="stylesheet"
              type="text/css" />
    % endfor
</%def>

<%def name="rss_feed(uri='/rss/', title='RSS Feed')">
    <link rel="alternate" type="application/rss+xml" title="${title}"
          href="${uri}" /> 
</%def>

