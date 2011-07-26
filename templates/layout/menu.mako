<%namespace file="/layout/page_title.mako" import="page_title" />

<%def name="simple(
    items=[],
    override={},
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
            <%
                if item in override:
                    title = override[item]
                else:
                    title = page_title(item)
            %>
            <span><a href="${item}">${title}</a></span>
        % endfor
    </div>
</%def>

<%def name="ul(
    items=[],
    override={},
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
        <%
                if item in override:
                    title = override[item]
                else:
                    title = page_title(item)
        %>
        <li><a href="${item}">%{title}</a></li>
        % endfor
        % for indication in indications:
            <li><span>${indication}</span></li>
        % endfor
    </ul>
</%def>

