<%doc>
    FORMULA: A library of functions to build forms from a data structure.
</%doc>

<%def name="form(fields, values={}, form_info={})">
    <%
        if form_info.get('skip_form_wrap'):
            unwrapped_form(fields=fields, values=values, form_info=form_info)
        else:
            wrapped_form(fields=fields, values=values, form_info=form_info)
    %>
</%def>

<%def name="wrapped_form(fields, values={}, form_info={})">
    <%
        action = form_info.get("action", "")
        method = form_info.get("method", "post")
        class_ = form_info.get("class", "")
        if class_:
            class_ = ' class="%s"' % cls
    %>
    <form ${class_}action="${action}" method="${method}">
        ${unwrapped_form(fields=fields, values=values, form_info=form_info)}
    </form>
</%def>

<%def name="unwrapped_form(fields, values={}, form_info={})">
    <%
        for item in fields:
            if isinstance(item, list):
                fieldset(item, values=values)
            elif isinstance(item, dict):
                dispatch_element(item, values=values)
            elif isinstance(item, str):
                explanatory(item)
        if not form_info.get('skip_buttonbar'):
            buttonbar(form_info)
    %>
</%def>

<%def name="dispatch_element(element, values={})">
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
        elif element_type == 'radio':
            radio(element, values=values)
    %>
</%def>

<%def name="explanatory(text)">
    <div class="explanatory">${text}</div>
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
        elem = 'unique_field_id'
        request_data.setdefault(elem, 0)
        id_ = request_data[elem]
        request_data[elem] += 1
        return id_
    %>
</%def>

<%def name="fieldset(fields, values={})">
    <%
        # Find legend
        legend = None
        for item in fields:
            if isinstance(item, list):
                legend = item[0]
                break
    %>
    <fieldset>
        % if legend:
            <legend>${legend}</legend>
        % endif
        % for item in fields:
            % if isinstance(item, dict):
                ${dispatch_element(item, values=values)}
            % elif isinstance(item, str):
                ${explanatory(item)}
            % endif
        % endfor
    </fieldset>

</%def>

<%def name="label(element)">
    <%
        if not 'id' in element:
            return
        element_id, label = element['id'], element['label']
    %>
    <label for="${element_id}">${label}</label>
</%def>

<%def name="input_checkbox(element, values={})">
    <%
        name = element['name']
        offset = element.get('offset', 0)
        value = get_value(name, value=values.get(name), offset=offset)

        attribs = {'name': name, 'type': 'checkbox'}
        if value:
            attribs['check'] = 'checked'
        context.write('<label>%s%s</label>' % 
                      (build_attribs(attribs, 'input'), element['label']))
        return
    %>
</%def>

<%def name="radio(element, values={})">
    <%
        out = ''
        name = element['name']
        labels = dict(zip(element['values'], element['labels']))
        offset = element.get('offset', 0)
        value = get_value(name, value=values.get(name), offset=offset)

        for val in element['values']:
            attribs = {'name': name, 'type': 'radio', 'value': val}
            if val == value:
                attribs['checked'] = 'checked'
            out += '<label>%s%s</label>' % (build_attribs(attribs, 'input'),
                                            labels[val])
        context.write(out)
        return
    %>
</%def>

<%def name="input_text(element, values={})">
    <%
        out = ''

        name = element['name']
        type_ = element.get('element_type', 'input_text')[6:]
        label = element.get('label')
        value = get_value(
            name,
            value=values.get(name, ''),
            offset=element.get('offset', 0),
        )

        attribs = {
            'name': name,
            'type': type_,
            'size': element.get('size', 32),
            'maxlength': element.get('maxlength', 64),
        }
        out = build_attribs(attribs, 'input')
        if label:
            out = '<label>%s%s</label>' % (label, out)
        context.write(out)
        return
    %>
</%def>

<%def name="build_attribs(attribs, tag=None)">
    <%
        items = []
        if tag:
            items.append('<' + tag)
        for attrib, value in attribs.iteritems():
            items.append('%s="%s"' % (attrib, value))
        if tag:
            items.append('/>')
        return ' '.join(items)
    %>
</%def>

<%def name="input_hidden(element, values={})">
    <%
        name = element['name']
        value = get_value(
            name,
            value=values.get(name, ''),
            offset=element.get('offset', 0),
        )

        attribs = {'name': name, 'type': 'hidden'}
        if value:
            attribs['value'] = value
        context.write(build_attribs(attribs, 'input'))
        return
    %>
</%def>

<%def name="textarea(element, values={})">
    <%
        name = element['name']
        label = element.get('label')
        value = get_value(
            name,
            value=values.get(name, ''),
            offset=element.get('offset', 0),
        )

        attribs = {
            'name': name,
            'rows': element.get('rows', 10),
            'cols': element.get('cols', 40),
            'maxlength': element.get('maxlength', 1024),
        }
        out = '<textarea %s>%s</textarea>' % (build_attribs(attribs), value)
        if label:
            out = '<label>%s%s</label>' % (label, out)
        context.write(out)
        return
    %>
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

## vim:ft=mako
