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
        attribs = {
            'action': form_info.get("action", ""),
            'method': form_info.get("method", "post"),
        }
        class_ = form_info.get("class", "")
        if class_:
            attribs['class'] = class_
    %>
    <form ${build_attribs(attribs)}>
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
        element.setdefault('id', 'unique-field-%s' % get_unique_field_id())

        handlers = {
            'text': input_text,
            'password': input_text,
            'textarea': textarea,
            'checkbox': checkbox,
            'radio': radio,
            'preserve': preserve,
        }
        type_ = element.get('type', 'text')
        try:
            handler = handlers[type_]
        except KeyError:
            return
        handler(element)
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
        <%
            for item in fields:
                if isinstance(item, dict):
                    dispatch_element(item)
                elif isinstance(item, str):
                    explanatory(item)
        %>
    </fieldset>

</%def>

<%def name="checkbox(element)">
    <%
        name = element['name']
        try:
            value = get_value(element)[0]
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
            value = get_value(element)[0]
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
        type_ = element.get('type', 'text')
        label = element.get('label')
        class_ = element.get('class', '').split()

        attribs = {
            'name': name,
            'type': type_,
            'size': element.get('size', 32),
            'maxlength': element.get('maxlength', 64),
        }

        if 'required' in element:
            class_.append('required')
            attribs['required'] = 'required'

        try:
            values = get_value(element)
        except KeyError:
            values = ['']

        if class_:
            attribs['class'] = ' '.join(class_)

        first = True
        for value in values:
            this_attribs = attribs.copy()
            if value is not None:
                value = str(value)
                if len(value):
                    attribs['value'] = value

            out = build_attribs(attribs, 'input')
            if first and label:
                out = '<label>%s%s</label>' % (label, out)
                first = False
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

<%def name="preserve(element)">
    <%doc>
        Preservation elements are used in cases where the presence of
        a field is optional. If a value for a preservation field is
        found in request.args, a hidden element will be placed into
        the form. This field will be recirculated continually through
        subsequent form submittals. This value may, of course, be
        altered in request.args at any time to change the value of
        the element. The value may even be removed from request.args,
        resulting in the removal of the hidden element.

        This may be used for various techniques, from extra parameters
        tucked into forms during initial generation, to step-wise
        forms that squirrel values away for a final submittal, and
        more.
    </%doc>
    <%
        if element['name'] in request.args:
            input_hidden(element)
        return
    %>
</%def>

<%def name="input_hidden(element)">
    <%
        name = element['name']
        try:
            values = get_value(element)
        except KeyError:
            values = ['']

        attribs = {'name': name, 'type': 'hidden'}
        for value in values:
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
            value = get_value(element)[0]
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
        return get_all_fields(fields)[0]
    %>
</%def>

<%def name="get_all_fields(fields)">
    <%
        all_fields = []
        for item in fields:
            if isinstance(item, dict):
                all_fields.append(item)
            elif isinstance(item, list):
                all_fields.extend(get_all_fields(item))
        return all_fields
    %>
</%def>

<%def name="field_is_not_preserve(field)">
    <%
        return field.get('type', text) != 'preserve'
    %>
</%def>

<%def name="arg_is_present(field)">
    <%
        if isinstance(field, dict):
            name = field['name']
            return name in request.args

        if isinstance(field, str):
            return field in request.args

        raise TypeError('field must be dict or str type')
    %>
</%def>

<%def name="form_is_first_round(fields)">
    <%
        return not arg_is_present(find_field(fields))
    %>
</%def>

## vim:ft=mako
