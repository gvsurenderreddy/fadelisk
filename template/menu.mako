<%namespace file="/page_title.mako" import="page_title" />

<%def name="simple(items=[], override={})">
% if len(items):
    <ul class="menu">
        <%
            for item in items:
                if item in override:
                    title = override[item]
                else:
                    title = page_title(item)
                context.write('<li><a href=\"%s\">%s</a></li>' % (item, title))
        %>
    </ul>
% endif
</%def>

<%def name="menu_list(items=[], override={})">
</%def>
