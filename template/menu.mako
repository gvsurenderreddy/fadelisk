<%!
    import fadelisk
%>

<%def name="simple(items=[], override={})">
<div id="menu">
% if len(items):
    <ul>
    % for item in items:
        <li><a href=\"%s\">${item}</a></li>
    % endfor
    </ul>
% endif
</div>
</%def>

<%def name="menu_list(items=[], override={})">
</%def>
