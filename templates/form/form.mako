<%doc>
    FORMULA: A library of functions to build forms from a data structure.
</%doc>

<%def name="form(fields=[], values={}, form_info={})">
    <%
        if form_info.get('skip_form_wrap'):
            unwrapped_form(fields=fields, values=values, form_info=form_info)
        else:
            wrapped_form(fields=fields, values=values, form_info=form_info)
    %>
</%def>

<%def name="wrapped_form(fields=[], values={}, form_info={})">
    <%
        action = form_info.get("action", "")
        method = form_info.get("method", "post")
        cls = form_info.get("class", None)
        if cls:
            cls = ' class="%s"' % cls
    %>
    <form ${cls}action="${action}" method="${method}">
        ${unwrapped_form(fields=fields, values=values, form_info=form_info)}
    </form>
</%def>

<%def name="unwrapped_form(fields=[], values={}, form_info={})">
    <%
        for item in fields:
            if isinstance(item, list):
                fieldset(item, values=values)
            elif isinstance(item, dict):
                dispatch_element(item, values=values)
            elif isinstance(item, str):
                context.write(item)
        if not form_info.get('skip_buttonbar'):
            buttonbar(form_info)
    %>
</%def>

<%def name="buttonbar(form_info={})">
    <%
        submit_label=form_info.get("submit_label", "Save")
    %>
    <div class="form-buttonbar">
    <input class="submit" type="submit" value="${submit_label}" />
    </div>
</%def>

<%def name="get_unique_field_id()">
    <%
        request_data.setdefault('unique_field_id', 0)
        return ++request_data['unique_field_id']
    %>
</%def>

<%def name="fieldset(fields=[], values={})">
    <%
        # Find legend
        legend = None
        for item in fields:
            if isinstance(item, list):
                legend = item[0]
    %>
    <fieldset>
        % if legend:
            <legend>${legend}</legend>
        % endif
        % for item in fields:
            % if isinstance(item, dict):
                ${dispatch_element(item, values=values)}
            % elif isinstance(item, str):
                ${item}
            % endif
        % endfor
    </fieldset>

</%def>

<%def name="dispatch_element(element={}, values={})">
    <%
        element_type = element.get('element_type', 'input_text')
        element.setdefault('id', 'unique-field-%s' % get_unique_field_id())

        if element_type == 'input_text' or element_type == 'input_password':
            input_text(element, values=values)
        elif element_type == 'input_hidden':
            input_hidden(element, values=values)
        elif element_type == 'textarea':
            textarea(element, values=values)
        elif element_type == 'checkbox':
            input_checkbox(element, values=values)
    %>
</%def>

<%def name="label(element)">
    <%
        if not 'id' in element:
            return
        element_id, label = element['id'], element['label']
    %>
    <label for="${element_id}">${label}</label><br/>
</%def>

<%def name="get_value(name, value='', attribute=False, offset=0)">
<%
    if name in request.args:
        value = request.args[name][offset]

    if attribute:
        return 'value="%s"' % value             # For form markup.
    return value                                # For general use.
%>
</%def>

<%def name="input_checkbox(element={}, values={})">
    <%
        html_out = []
        name = element['name']

        # *BEFORE
        html_out.append('<input type="checkbox"')
        #html_out.append(' type="%s"' % element.get('input_type', 'text'))
        value = bool(get_value(
            name,
            value=values.get(name, ''),
            offset=element.get('offset', 0),
        ))
        if value:
            html_out.append(' checked="checked"')
        # *VALUE: fetch, include offset
        for attr in 'name style id'.split():
            if attr in element:
                html_out.append(' %s="%s"' % (attr, element[attr]))
        # *CLASS: join in 'input-hilight'
        html_out.append(' />')
        # *AFTER
        # *REQUIRED
        if 'label' in element:
            html_out.extend(label(element))
        html_out.append('<br />')
    %>
    ${''.join(html_out)}
</%def>

<%def name="input_text(element={}, values={})">
    <%
        html_out = []
        name = element['name']

        if 'label' in element:
            html_out.extend(label(element))
        # *BEFORE
        html_out.append('<input')
        html_out.append(' type="%s"' % element.get('input_type', 'text'))
        value = get_value(
            name,
            value=values.get(name, ''),
            offset=element.get('offset', 0),
        )
        if value:
            html_out.append(' value="%s"' % value)
        # *VALUE: fetch, include offset
        for attr in 'name size maxlength style'.split():
            if attr in element:
                html_out.append(' %s="%s"' % (attr, element[attr]))
        # *CLASS: join in 'input-hilight'
        html_out.append(' />')
        # *AFTER
        # *REQUIRED
        html_out.append('<br />')
    %>
    ${''.join(html_out)}
</%def>

<%def name="input_hidden(element={}, values={})">
    <%
        html_out = []
        name = element['name']

        html_out.append('<input type="hidden" name="%s"' % name)
        # *VALUE: fetch, include offset
        value = get_value(
            name,
            value=values.get(name, ''),
            offset=element.get('offset', 0),
        )
        if value:
            html_out.append(' value="%s"' % value)
        html_out.append(' />')
        html_out.append('<br />')
    %>
    ${''.join(html_out)}
</%def>

<%def name="textarea(element={}, values={})">
    <%
        html_out = []
        name = element['name']

        if 'label' in element:
            html_out.extend(label(element))
        # *BEFORE
        html_out.append(
            '<textarea rows="%s" cols="%s" maxlength="%s"' % (
                element.get('rows', 25),
                element.get('cols', 80),
                element.get('maxlength', 8192),
            )
        )
        for attr in 'name class style'.split():
            if attr in element:
                html_out.append(' %s="%s"' % (attr, element[attr]))
        # *CLASS: join in 'input-hilight'
        html_out.append('>')
        # *VALUE: fetch, include offset
        html_out.append(get_value(
            name,
            value=values.get(name, ''),
            offset=element.get('offset', 0),
        ))
        # *AFTER
        # *REQUIRED
        html_out.append('</textarea><br />')
    %>
    ${''.join(html_out)}
</%def>

## vim:ft=mako
