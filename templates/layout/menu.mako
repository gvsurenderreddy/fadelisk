<%namespace file="/layout/page_title.mako" import="page_title" />

<%def name="simple(
    items=[],
    override={},
    tooltip={},
    element_class=None,
    element_id=None
    )">
    <%
        # Add in classes and IDs
        class_id = ''
        if element_class:
            class_id += ' class="%s"' % element_class
        if element_id:
            class_id += ' id="%s"' % element_id
    %>
    <div${class_id}>
        % for item in items:
            <span>${menu_button(item, override, tooltip)}</span>
        % endfor
    </div>
</%def>

<%def name="menu_button(path, override={}, tooltip={})">
    <%
        if path in override:
            label = override[path]
        else:
            label = page_title(path)
        title = ''
        if path in tooltip:
            title = ' title="%s"' % tooltip[path]
    %>
    <a href="${path}"${title}>${label}</a>
</%def>

<%def name="ul(
    items=[],
    override={},
    tooltip={},
    indications=[],
    element_class=None,
    element_id=None
    )">
    <%
        # Add in classes and IDs
        class_id = ''
        if element_class:
            class_id += ' class="%s"' % element_class
        if element_id:
            class_id += ' id="%s"' % element_id
    %>
    <ul${class_id}>
        % for item in items:
                 <li>${menu_button(item, override, tooltip)}</li>
        % endfor
        % for indication in indications:
            <li><span>${indication}</span></li>
        % endfor
    </ul>
</%def>

