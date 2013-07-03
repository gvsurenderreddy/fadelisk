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
        context.write(wrap_tags('form',
                capture(unwrapped_form, fields, form_info, error), attribs))
    %>
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
            value = str(values[index])
            id_ = None

            if label and not index:
                id_ = '%s-%s' % (name, get_unique_field_id())
                context.write(wrap_tags('label', label, {'for': id_}))
                this_attribs['id'] = id_
            if len(value):
                this_attribs['value'] = value
            if is_error(field, index, error):
                this_class.append('error')
            if is_required(field, index):
                this_attribs['required'] = 'required'
                this_class.append('required')
            if this_class:
                this_attribs['class'] = ' '.join(this_class)
            out = build_tag(this_attribs, 'input', void=True)
            context.write(out)
    %>
</%def>

<%def name="textarea(field, error={})">
    <%
        name = field['name']
        lbl = field.get('label')
        class_ = field.get('class', '').split()
        try:
            values = get_values(field)
        except KeyError:
            values = ['']

        attribs = {
            'name': name,
            'rows': field.get('rows', 10),
            'cols': field.get('cols', 40),
            'maxlength': field.get('maxlength', 4096),
        }
        for index in range(len(values)):
            this_class = list(class_) # copy
            this_attribs = attribs.copy()
            value = str(values[index])
            id_ = None

            if lbl and not index:
                id_ = '%s-%s' % (name, get_unique_field_id())
                label(lbl, id_)
                this_attribs['id'] = id_
            out = wrap_tags('textarea', value, this_attribs)
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
            value = str(values[index])
            id_ = '%s-%s' % (name, get_unique_field_id())
            this_attribs['id'] = id_
            if value:
                this_attribs['checked'] = 'checked'
            ckbox = capture(input_, this_attribs)
            lbl = capture(label, field['label'], id_)
            context.write(wrap_tags('div', ckbox + lbl, {'class': 'checkbox'}))
    %>
</%def>

<%def name="radio(field, error)">
    <%
        name = field['name']
        lbl = field.get('label')
        desc = dict(zip(field['choices'], field['descriptions']))
        try:
            value = get_values(field)[0]
        except:
            value = ''
        attribs = {'name': name, 'type': 'radio'}

        out = ''
        if lbl:
            out += label(lbl)
        for choice in field['choices']:
            id_ = '%s-%s' % (name, get_unique_field_id())
            this_attribs = attribs.copy()
            this_attribs['value'] = choice
            this_attribs['id'] = id_
            if choice == value:
                this_attribs['checked'] = 'checked'
            out += wrap_tags(
                'div',
                (capture(input_, this_attribs) +
                    capture(label, desc[choice], id_)),
                {'class': 'radio'})
        context.write(out)
    %>
</%def>

<%def name="label(content, for_id=None)">
    <%
        attribs = {}
        if for_id:
            attribs['for'] = for_id
    %>
    ${wrap_tags('label', content, attribs)}
</%def>

<%def name="input_(attribs)">
    ${build_tag(attribs, 'input', void=True)}
</%def>

<%def name="select(field, error={})">
    <%
        name = field['name']
        lbl = field.get('label')
        class_ = field.get('class', '').split()
        desc = dict(zip(field['choices'], field['descriptions']))
        attribs = {'name': name}
        try:
            values = get_values(field)
        except:
            values = ['']

        for index in range(len(values)):
            this_class = list(class_) # copy
            this_attribs = attribs.copy()
            value = str(values[index])
            id_ = None

            if lbl and not index:
                id_ = '%s-%s' % (name, get_unique_field_id())
                context.write(label(lbl, id_))
                this_attribs['id'] = id_
            out = ''
            for choice in field['choices']:
                choice_attribs = {'value': choice}
                if choice == value:
                    choice_attribs['selected'] = 'selected'
                out += wrap_tags('option', desc[choice], choice_attribs)
            context.write(wrap_tags('select', out, this_attribs))
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
            attribs['value'] = str(value)
            context.write(input_(attribs))
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

<%def name="wrap_tags(tag, content='', attribs={})">
    <%
        return '%s%s</%s>' % (build_tag(attribs, tag), content, tag) 
    %>
</%def>

<%def name="build_tag(attribs, tag=None, void=False)">
    <%
        items = []
        if tag:
            items.append('<' + tag)
        for attrib, value in attribs.iteritems():
            items.append('%s=%s' % (attrib, quoteattr(str(value))))
        out = ' '.join(items)
        if tag:
            if void:
                out += ' /'
            out += '>'
        return out
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
