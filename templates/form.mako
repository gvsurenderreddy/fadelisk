<%doc>
    FORMULA: A library of functions to build forms from a data structure.
</%doc>

<%!
    from xml.sax.saxutils import quoteattr
%>

##:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::( form )

<%def name="form(fields, form_info={}, error={})">
    <%
        if form_info.get('skip_form_wrap'):
            unwrapped_form(fields, form_info, error)
        else:
            wrapped_form(fields, form_info, error)
    %>
</%def>

<%def name="wrapped_form(fields, form_info={}, error={})">
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
        ${unwrapped_form(fields, form_info, error)}
    </form>
</%def>

<%def name="unwrapped_form(fields, form_info={}, error={})">
    <%
        for field in fields:
            if isinstance(field, list):
                fieldset(field, error)
            elif isinstance(field, dict):
                dispatch_field(field, error)
            elif isinstance(field, str):
                explanatory(field)
        if not form_info.get('skip_buttonbar'):
            buttonbar(form_info)
    %>
</%def>

<%def name="dispatch_field(field, error={})">
    <%
        handlers = {
            'text': input_text,
            'password': input_text,
            'textarea': textarea,
            'checkbox': checkbox,
            'radio': radio,
            'select': select,
            'preserve': preserve,
        }
        type_ = field.get('type', 'text')
        try:
            handler = handlers[type_]
        except KeyError:
            return
        handler(field, error)
    %>
</%def>

<%def name="buttonbar(form_info={})">
    <%
        submit_label=form_info.get("submit_label", "Save")
        cancel = form_info.get('cancel')
    %>
    <div class="form-buttonbar">
        % if cancel:
            <a class="button-danger" href="${cancel}">Cancel</a>
        % endif
        <input class="submit" type="submit" value="${submit_label}" />
    </div>
</%def>

##:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::( elements )

<%def name="fieldset(fields, error)">
    <%
        # Find legend
        legend = None
        for field in fields:
            if isinstance(field, list):
                legend = field[0]
                break
    %>
    <fieldset>
        % if legend:
            <legend>${legend}</legend>
        % endif
        <%
            for field in fields:
                if isinstance(field, dict):
                    dispatch_field(field, error)
                elif isinstance(field, str):
                    explanatory(field)
        %>
    </fieldset>
</%def>

<%def name="input_text(field, error={})">
    <%
        name = field['name']
        type_ = field.get('type', 'text')
        label = field.get('label')
        class_ = field.get('class', '').split()

        attribs = {
            'name': name,
            'type': type_,
            'size': field.get('size', 32),
            'maxlength': field.get('maxlength', 64),
        }

        try:
            values = get_values(field)
        except KeyError:
            values = ['']

        for index in range(len(values)):
            this_class = list(class_) # copy
            this_attribs = attribs.copy()
            value = values[index]
            if value is not None:
                value = str(value)
                if len(value):
                    this_attribs['value'] = value
            if is_error(field, index, error):
                this_class.append('error')
            if is_required(field, index):
                this_attribs['required'] = 'required'
                this_class.append('required')
            if this_class:
                this_attribs['class'] = ' '.join(this_class)

            out = build_attribs(this_attribs, 'input')
            if not index and label:
                out = '<label>%s%s</label>' % (label, out)
            context.write(out)
    %>
</%def>

<%def name="textarea(field, error={})">
    <%
        name = field['name']
        label = field.get('label')
        try:
            value = get_values(field)[0]
        except KeyError:
            value = ''

        attribs = {
            'name': name,
            'rows': field.get('rows', 10),
            'cols': field.get('cols', 40),
            'maxlength': field.get('maxlength', 1024),
        }
        out = '<textarea %s>%s</textarea>' % (build_attribs(attribs), value)
        if label:
            out = '<label>%s%s</label>' % (label, out)
        context.write(out)
    %>
</%def>

<%def name="checkbox(field, error)">
    <%
        name = field['name']

        try:
            values = get_values(field)
        except KeyError:
            values = ['']
        attribs = {'name': name, 'type': 'checkbox'}

        for index in range(len(values)):
            this_attribs = attribs.copy()
            value = values[index]
            if value:
                this_attribs['checked'] = 'checked'
            out = build_attribs(this_attribs, 'input')
            context.write('<label>%s%s</label>' % (out, field['label']))
    %>
</%def>

<%def name="radio(field, error)">
    <%
        name = field['name']
        choices = field['choices']
        label = field.get('label')
        descriptions = dict(zip(choices, field['descriptions']))
        try:
            value = get_values(field)[0]
        except:
            value = ''
        attribs = {'name': name, 'type': 'radio'}

        out = ''
        for choice in choices:
            this_attribs = attribs.copy()
            if choice == value:
                this_attribs['checked'] = 'checked'
            tag = build_attribs(this_attribs, 'input')
            out += '<label>%s%s</label>' % (tag, descriptions[choice])
        if label:
            out = '<div class="label">%s%s</div>' % (label, out)
        context.write(out)
    %>
</%def>

<%def name="select(field, error={})">
    <%
        name = field['name']
        label = field.get('label')
        choices = field['choices']
        descriptions = dict(zip(choices, field['descriptions']))
        try:
            value = get_values(field)[0]
        except:
            value = ''
        attribs = {'name': name}

        out = '<select>'
        for choice in choices:
            this_attribs = {'value': choice}
            if choice == value:
                this_attribs['selected'] = 'selected'
            out += '<option ' + build_attribs(this_attribs) 
            out += '>' + descriptions[choice] + '</option>'
        out += '</select>'
        if label:
            out = '<label>%s%s</label>' % (label, out)
        context.write(out)
    %>
</%def>

<%def name="input_hidden(field, error={})">
    <%
        name = field['name']
        try:
            values = get_values(field)
        except KeyError:
            values = ['']

        attribs = {'name': name, 'type': 'hidden'}
        for value in values:
            attribs['value'] = value
            context.write(build_attribs(attribs, 'input'))
    %>
</%def>

<%def name="explanatory(text)">
    <div class="explanatory">${text}</div>
</%def>

<%def name="preserve(field, error={})">
    <%doc>
        Preservation fields are used in cases where the presence of
        a field is optional. If a value for a preservation field is
        found in request.args, a hidden field will be placed into
        the form. This field will be recirculated continually through
        subsequent form submittals. This value may, of course, be
        altered in request.args at any time to change the value of
        the field. The value may even be removed from request.args,
        resulting in the removal of the hidden field.

        This may be used for various techniques, from extra parameters
        tucked into forms during initial generation, to step-wise
        forms that squirrel values away for a final submittal, and
        more.
    </%doc>
    <%
        if arg_is_present(field):
            input_hidden(field)
    %>
</%def>

##::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::( operators )

<%def name="is_required(field, index)">
    <%
        try:
            return field['required'][index]
        except:
            return False
    %>
</%def>

<%def name="is_error(field, index, error)">
    <%
        if isinstance(field, dict):
            field = field['name']
        try:
            return error[field][index]
        except:
            return False
    %>
</%def>

<%def name="build_attribs(attribs, tag=None)">
    <%
        items = []
        if tag:
            items.append('<' + tag)
        for attrib, value in attribs.iteritems():
            items.append('%s=%s' % (attrib, quoteattr(str(value))))
        if tag:
            items.append('/>')
        return ' '.join(items)
    %>
</%def>

<%def name="get_values(field)">
<%
    if isinstance(field, dict):
        try:
            return field['values']
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
        for field in fields:
            if isinstance(field, dict):
                all_fields.append(field)
            elif isinstance(field, list):
                all_fields.extend(get_all_fields(field))
        return all_fields
    %>
</%def>

<%def name="field_is_not_preserve(field)">
    <%
        return field.get('type', text) != 'preserve'
    %>
</%def>

<%def name="set_error(field, index, error)">
    <%
        if isinstance(field, dict):
            field = field['name']
        if not arg_is_present(field):
            return
        error.setdefault(field [False] * len(request.args[field]))
        error[field][index] = True
    %>
</%def>

<%def name="arg_is_present(field)">
    <%
        if isinstance(field, dict):
            field = field['name']
        return field in request.args
    %>
</%def>

<%def name="form_is_first_round(fields)">
    <%
        return not arg_is_present(find_field(fields))
    %>
</%def>

<%def name="get_unique_field_id()">
    <%
        key = 'unique_field_id'
        request_data.setdefault(key, 0)
        id_ = request_data[key]
        request_data[key] += 1
        return id_
    %>
</%def>

## vim:ft=mako
