<%namespace name="title_utils" file="/title.mako" />
<%namespace name="menu" file="/menu.mako" />

<%def name="head()">
    ${'<head>'}
        <meta charset="utf-8" />
        <link rel="icon" href="/images/favicon.png" type="image/png" />
        <% site_name = site.conf.get('site_name', '') %>
        <title>
            ${site_name}${':' if site_name else ''}
            ${title_utils.breadcrumbs(no_links=True, no_home_link=True)}
        </title>
        ${stylesheets()}
        ${fonts()}
        ${google_fonts()}
        ${scripts()}
        ${rss_feed()}
        ${extra_head_content()}
    ${'</head>'}
</%def>

<%def name="stylesheets()">
    ${stylesheets_of_media('all')}
    ${stylesheets_of_media('screen')}
    ${stylesheets_of_media('print')}
</%def>

<%def name="stylesheets_of_media(media='all')">
    <%

        if media == 'all':
            main = 'stylesheets'
        else:
            main = media + '_stylesheets'
        extra = 'extra_' + main

        stylesheets = list(site.conf.get(main) or [])
        stylesheets.extend(request_data.get(extra) or [])
    %>
    % for stylesheet in stylesheets:
        <link rel="stylesheet" media="${media}" href="${stylesheet}" />
    % endfor
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

<%def name="fonts(uri='/fonts')">
    <%
        content = capture(fonts_content, uri)
        if not content:
            return ''
    %>
    <style type="text/css">
        ${content}
    </style>
</%def>

<%def name="fonts_content(uri='/fonts')">
    <%
        fonts_ = list(site.conf.get('fonts') or [])
        fonts_.extend(request_data.get('extra_fonts') or [])
        if not fonts_:
            return ''
    %>
    % for font in fonts_:
        <%
            spec = dict(enumerate(font.split(':')))

            family = spec[0]
            style = spec.get(1) or 'normal'
            weight = spec.get(2) or  '400'
            locals_ = (spec.get(3) or family).split(',')
            format_ = spec.get(4) or 'woff2'

            filename = locals_[0]
            locals_[0] = locals_[0].split('/')[-1]
        %>
        @font-face {
            font-family: '${family}';
            font-style: ${style};
            font-weight: ${weight};
            src: ${', '.join(["local('%s')" % f for f in locals_])},
                url(${uri}/${filename}.${format_}) format('${format_}');
        }
    % endfor
</%def>

<%def name="google_fonts(uri='https://fonts.googleapis.com/css?family=')">
    <%
        fonts = site.conf.get('google_fonts', [])
        if not fonts:
            return ''
        stylesheet = uri + '|'.join([f.replace(' ', '+') for f in fonts])
    %>
    <link href="${stylesheet}" rel="stylesheet" type="text/css" />
</%def>

<%def name="rss_feed(uri='/rss/', title='RSS Feed',
    mime_type='application/rss+xml')">
    <link rel="alternate" type="${mime_type}" title="${title}" href="${uri}" /> 
</%def>

<%def name="extra_head_content()">
    ${''.join(request_data.get('extra_head_content', []))}
</%def>

