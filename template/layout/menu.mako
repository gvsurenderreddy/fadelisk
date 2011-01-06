<%namespace file="/layout/page_title.mako" import="page_title" />

<%def name="simple(items=[], override={}, indications=[])">
% if len(items):
    <ul class="menu">
        <%
            for item in items:
                if item in override:
                    title = override[item]
                else:
                    title = page_title(item)
                context.write('<li><a href=\"%s\">%s</a></li>' % (item, title))
            for indication in indications:
                context.write('<li><span>%s</span></li>' % indication)
        %>
    </ul>
% endif
</%def>

