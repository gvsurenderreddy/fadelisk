<%doc>
    FORMULA: A library of functions to build forms from a data structure.
</%doc>

<%!
    import copy
    from xml.sax.saxutils import quoteattr
    from bson.objectid import ObjectId
%>

##:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::( form )

<%def name="form(fields, values={}, error={}, 
    form_class='', form_action='', http_method='post',
    submit_label='Save', cancel_uri=None,
    wrap=True, buttonbar=True)">
    <%
        # Build the inner form.
        buff = []
        for field in fields:
            if isinstance(field, list):
                buff.append(capture(fieldset, field, values, error))
            elif isinstance(field, dict):
                buff.append(capture(dispatch_field, field, values, error))
            elif isinstance(field, str):
                buff.append(capture(explanatory, field))
        if buttonbar:
            buff.append(capture(form_buttonbar, submit_label, cancel_uri))
        content = ''.join(buff)

        # Full form: wrap with tags.
        if wrap:
            attribs = {
                'method': http_method,
                'action': form_action,
                'class': form_class,
            }
            content = wrap_tags('form', content, attribs)
    %>
    ${content}
</%def>

<%def name="form_buttonbar(submit_label='Save', cancel_uri=None)">
    <div class="form-buttonbar">
        % if cancel_uri:
            <a class="button-danger" href="${cancel_uri}">Cancel</a>
        % endif
        <input type="submit" value="${submit_label}" />
    </div>
</%def>

<%def name="dispatch_field(field, values={}, error={})">
    <%
        handlers = {
            'text': input_text,
            'password': input_text,
            'textarea': textarea,
            'checkbox': checkbox,
            'radio': radio,
            'select': select,
            'hidden': input_hidden,
            'preserve': input_preserve,
        }
        type_ = field.get('type', 'text')
        try:
            handler = handlers[type_]
        except KeyError:
            return
        handler(field, values, error)
    %>
</%def>

##:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::( elements )

<%def name="fieldset(fields, values, error)">
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
                    dispatch_field(field, values, error)
                elif isinstance(field, str):
                    explanatory(field)
        %>
    </fieldset>
</%def>

<%def name="input_text(field, values={}, error={})">
    <%
        name = field['name']
        type_ = field.get('type', 'text')
        label = field.get('label')
        class_ = field.get('class', '').split()
        vals = get_field_values(field, values)

        attribs = {
            'name': name,
            'type': type_,
            'size': field.get('size', 32),
            'maxlength': field.get('maxlength', 64),
        }

        if not len(vals):
            return

        context.write('<div class="input-text">')
        for index in range(len(vals)):
            this_class = list(class_) # copy
            this_attribs = attribs.copy()
            value = unicode(vals[index])
            id_ = None

            if label and not index:
                id_ = '%s-%s' % (name, get_unique_field_id())
                context.write(wrap_tags('label', label, {'for': id_}))
                this_attribs['id'] = id_
            if len(value):
                this_attribs['value'] = value
            if is_error(field, error, index):
                this_class.append('error')
            if is_required(field, index):
                this_attribs['required'] = 'required'
                this_class.append('required')
            if this_class:
                this_attribs['class'] = ' '.join(this_class)
            out = build_tag(this_attribs, 'input', void=True)
            context.write(out)
        context.write('</div>')
    %>
</%def>

<%def name="textarea(field, values={}, error={})">
    <%
        name = field['name']
        lbl = field.get('label')
        class_ = field.get('class', '').split()
        vals = get_field_values(field, values)

        attribs = {
            'name': name,
            'rows': field.get('rows', 10),
            'cols': field.get('cols', 40),
            'maxlength': field.get('maxlength', 4096),
        }
        for index in range(len(vals)):
            this_class = list(class_) # copy
            this_attribs = attribs.copy()
            value = unicode(vals[index])
            id_ = None

            if lbl and not index:
                id_ = '%s-%s' % (name, get_unique_field_id())
                label(lbl, id_)
                this_attribs['id'] = id_
            out = wrap_tags('textarea', value, this_attribs)
            context.write(out)
    %>
</%def>

<%def name="checkbox(field, values={}, error={})">
    <%
        name = field['name']
        vals = get_field_values(field, values)
        attribs = {'name': name, 'type': 'checkbox'}

        for index in range(len(vals)):
            this_attribs = attribs.copy()
            value = unicode(vals[index])
            id_ = '%s-%s' % (name, get_unique_field_id())
            this_attribs['id'] = id_
            if value:
                this_attribs['checked'] = 'checked'
            ckbox = capture(input_, this_attribs)
            lbl = capture(label, field['label'], id_)
            context.write(wrap_tags('div', ckbox + lbl, {'class': 'checkbox'}))
    %>
</%def>

<%def name="radio(field, values={}, error={})">
    <%
        name = field['name']
        lbl = field.get('label')
        desc = dict(zip(field['choices'], field['descriptions']))
        value = get_field_values(field, values)[0]
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

<%def name="select(field, values={}, error={})">
    <%
        name = field['name']
        lbl = field.get('label')
        class_ = field.get('class', '').split()
        desc = dict(zip(field['choices'], field['descriptions']))
        attribs = {'name': name}
        vals = get_field_values(field, values)

        for index in range(len(vals)):
            this_class = list(class_) # copy
            this_attribs = attribs.copy()
            value = unicode(vals[index])
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

<%def name="get_field_values(field, values={})">
    <%
        name = field['name']
        #-- Explicit values passed in form override all.
        if 'values' in field:
            return field['values']
        #-- Extract them from values structure
        if name in values:
            return values[name]
        #-- Default: one field with no value.
        return ['']
    %>
</%def>

<%def name="input_hidden(field, values={}, error={})">
    <%
        vals = get_field_values(field, values)

        attribs = {'name': field['name'], 'type': 'hidden'}
        for value in vals:
            attribs['value'] = unicode(value)
            context.write(input_(attribs))
    %>
</%def>

<%def name="explanatory(text)">
    <div class="explanatory">${text}</div>
</%def>

<%def name="input_preserve(field, values={}, error={})">
    <%
        name = field['name']
        vals = None
        if arg_is_present(name):
            vals = request.args[name]
        else:
            vals = get_field_values(field, values)
        if vals and (vals != ['']):
            input_hidden(field, {name: vals})
    %>
</%def>

##::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::( operators )

<%def name="preserve(field, values)">
    <%
        if isinstance(field, dict):
            field = field['name']
        if arg_is_present(field):
            values[field] = request.args[field]
    %>
</%def>

<%def name="is_required(field, index=0)">
    <%
        try:
            return field['required'][index]
        except:
            return False
    %>
</%def>

<%def name="is_error(field, error, index)">
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
            if value is None:
                continue
            if not isinstance(value, basestring):
                value = unicode(value)
            if len(value):
                items.append('%s=%s' % (attrib, quoteattr(unicode(value))))
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

##<%def name="field_is_not_preserve(field)">
##    <%
##        return field.get('type', text) != 'preserve'
##    %>
##</%def>

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

<%def name="request_args_deepcopy()">
    <%
        return copy.deepcopy(request.args)
    %>
</%def>

<%def name="args_to_data(fields, args=None)">
    <%
        #fields = form.get_all_fields(self.attr.fields)
        flat_fields = get_all_fields(fields)            # "Flatten" the fields
        if not args:                                    # Might pass args
            args = request.args

        data = {}
        for field in flat_fields:
            if field.get('type') == 'preserve': # Preserves aren't part of data
                continue
            name = field.get('name')
            if name not in args:                # Not in form for some reason?
                continue                        # TODO: Should warn to log

            values = filter(bool, request.args[name]) # Only non-empty strings
            if not values:                      # Any left?
                continue
            if len(values) == 1:                # Unwrap single value
                values = values[0]

            nodes = name.split('__')            # TODO: Reasonable separator?
            this_node = data                    # Start at top
            for node in nodes[:-1]:             # Provide dictionary tree
                this_node = this_node.setdefault(node, {})
            this_node[nodes[-1]] = values       # Values at bottom level

        if 'id' in args:                        # TODO: Move to DB interface
            data['_id'] = ObjectId(args['id'][0])

        return data
    %>
</%def>

<%def name="data_to_values(data)">
    <%
        values = {}

        form_name = []
        def node_name():
            return '__'.join(form_name)
        def descend(thing):
            for name, item in thing.iteritems():
                form_name.append(name)
                if isinstance(item, dict):
                    descend(item)
                elif isinstance(item, list):
                    values[node_name()] = item
                else:
                    values[node_name()] = [unicode(item)]
                form_name.pop()
        descend(data)

        return values
    %>
</%def>

## vim:ft=mako
