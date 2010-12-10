<%namespace file="/page_title.mako" import="page_title" />

<%def name="simple(items=[], override={})">
<div id="menu">
% if len(items):
    <ul>
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
</div>
</%def>

<%def name="menu_list(items=[], override={})">
</%def>
