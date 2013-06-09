<%doc>
    FORMULA: A library of functions to build forms from a data structure.
</%doc>

<%def name="form(fields, form_info={})">
    <%
        if form_info.get('skip_form_wrap'):
            unwrapped_form(fields=fields, form_info=form_info)
        else:
            wrapped_form(fields=fields, form_info=form_info)
    %>
</%def>

<%def name="wrapped_form(fields, form_info={})">
    <%
        action = form_info.get("action", "")
        method = form_info.get("method", "post")
        class_ = form_info.get("class", "")
        if class_:
            class_ = ' class="%s"' % cls
    %>
    <form ${class_}action="${action}" method="${method}">
        ${unwrapped_form(fields=fields, form_info=form_info)}
    </form>
</%def>

<%def name="unwrapped_form(fields, form_info={})">
    <%
        for item in fields:
            if isinstance(item, list):
                fieldset(item)
            elif isinstance(item, dict):
                dispatch_element(item)
            elif isinstance(item, str):
                explanatory(item)
        if not form_info.get('skip_buttonbar'):
            buttonbar(form_info)
    %>
</%def>

<%def name="dispatch_element(element)">
    <%
        element_type = element.get('element_type', 'input_text')
        element.setdefault('id', 'unique-field-%s' % get_unique_field_id())

        if element_type == 'input_text' or element_type == 'input_password':
            input_text(element)
        elif element_type == 'input_hidden':
            input_hidden(element)
        elif element_type == 'textarea':
            textarea(element)
        elif element_type == 'checkbox':
            input_checkbox(element)
        elif element_type == 'radio':
            radio(element)
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

<%def name="fieldset(fields)">
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
                ${dispatch_element(item)}
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

<%def name="input_checkbox(element)">
    <%
        name = element['name']
        try:
            value = get_value(element)
        except KeyError:
            value = ''

        attribs = {'name': name, 'type': 'checkbox'}
        if value:
            attribs['check'] = 'checked'
        context.write('<label>%s%s</label>' % 
                      (build_attribs(attribs, 'input'), element['label']))
        return
    %>
</%def>

<%def name="radio(element)">
    <%
        out = ''
        name = element['name']
        labels = dict(zip(element['values'], element['labels']))
        try:
            value = get_value(element)
        except KeyError:
            value = ''

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

<%def name="input_text(element)">
    <%
        out = ''

        name = element['name']
        type_ = element.get('element_type', 'input_text')[6:]
        label = element.get('label')
        try:
            value = get_value(element)
        except KeyError:
            value = ''

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

<%def name="input_hidden(element)">
    <%
        name = element['name']
        try:
            value = get_value(element)
        except KeyError:
            value = ''

        attribs = {'name': name, 'type': 'hidden'}
        if value:
            attribs['value'] = value
        context.write(build_attribs(attribs, 'input'))
        return
    %>
</%def>

<%def name="textarea(element)">
    <%
        name = element['name']
        label = element.get('label')
        try:
            value = get_value(element)
        except KeyError:
            value = ''

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

<%def name="get_value(field)">
<%
    if isinstance(field, dict):
        try:
            return field['value']
        except KeyError:
            return request.args[field['name']]

    if isinstance(field, str):
        return request.args[field]

    raise TypeError('field must be dict or str type')
%>
</%def>

<%def name="find_field(fields)">
    <%
        for item in fields:
            if isinstance(item, dict):
                return item
            elif isinstance(item, list):
                for fieldset_item in item:
                    if isinstance(fieldset_item, dict):
                        return fieldset_item
        return None
    %>
</%def>

<%def name="form_is_first_round(fields)">
    <%
        if find_field(fields)['name'] in request.args:
            return False
        return True
    %>
</%def>
## vim:ft=mako
