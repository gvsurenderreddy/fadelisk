<%namespace name="title_utils" file="/title.mako" />

<%def name="menu_simple(items=[], overrides={}, tooltips={},
    element_class=None, element_id=None)">
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
            <span>${menu_button(item, overrides, tooltips)}</span>
        % endfor
    </div>
</%def>

<%def name="menu_button(path, overrides={}, tooltips={},
    highlight_current=False)">
    <%
        try:
            label = overrides[path]
        except:
            label = title_utils.title(path)

        title = ''
        if path in tooltips:
            title = ' title="%s"' % tooltips[path]

        cls = ''
        if highlight_current and page_info.is_current_path(path):
            cls = ' class="current"'
    %>
    <a${cls} href="${path}"${title}>${label}</a>
</%def>

<%def name="menu_ul(items=[], overrides={}, tooltips={}, indications=[],
    element_class=None, element_id=None, highlight_current=False)">
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
            <li>${menu_button(item, overrides, tooltips, highlight_current)}</li>
        % endfor
        % for indication in indications:
            <li><span>${indication}</span></li>
        % endfor
    </ul>
</%def>

<%def name="nav(items, overrides={})">
    <nav>
    ${menu_ul(items=items, overrides=overrides)}
    </nav>
</%def>

