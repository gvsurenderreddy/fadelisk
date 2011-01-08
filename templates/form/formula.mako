<%doc>

form.get_value('title', value=article['title'])
</%doc>

<%namespace name="form" file="/form.mako" />

<%def name="formula(fields=[], values={}, form_info={})">
    <%
        html_out = []
        if not form_info.get('skip_form_wrap'):
            html_out.append('<form action="" method="post">')

        for item in fields:
            if isinstance(item, dict):
                html_out.extend(dispatch_element(item, values=values))
            elif isinstance(item, list):
                html_out.extend(fieldset(item, values=values))
            elif isinstance(item, str):
                html_out.append(item)

        if not form_info.get('skip_buttonbar'):
            html_out.append('<div class="form-buttonbar">')
            html_out.append('<input class="submit" type="submit" value="Save" />')
            html_out.append('</div>')
        if not form_info.get('skip_form_wrap'):
            html_out.append('</form>')

        return "\n".join(html_out)
    %>
</%def>

<%def name="get_unique_field_id()">
    <%
        request_data.setdefault('unique_field_id', 0)
        return ++request_data['unique_field_id']
    %>
</%def>

<%def name="fieldset(fields=[], values={})">
    <%
        html_out = []
        legend = None

        for item in fields:
            if isinstance(item, dict):
                html_out.extend(dispatch_element(item, values=values))
            elif isinstance(item, list):
                if not legend:
                    legend = item[0]
            elif isinstance(item, str):
                html_out.append(item)

        if legend:
            html_out.insert(0, '<legend>%s</legend>' % legend)

        html_out.insert(0, '<fieldset>')        # wrap fieldset
        html_out.append('</fieldset>')

        return html_out
    %>
</%def>

<%def name="dispatch_element(element={}, values={})">
    <%
        html_out = []

        element_type = element.get('element_type', 'input_text')
        element.setdefault('id', 'unique-field-%s' % get_unique_field_id())

        if element_type == 'input_text' or element_type == 'input_password':
            html_out.extend(input_text(element, values=values))
        elif element_type == 'input_hidden':
            html_out.extend(input_hidden(element, values=values))
        elif element_type == 'textarea':
            html_out.extend(textarea(element, values=values))
        elif element_type == 'checkbox':
            html_out.extend(input_checkbox(element, values=values))

        return html_out
    %>
</%def>

<%def name="label(element)">
    <%
        if not 'id' in element:
            return
        element_id, label = element['id'], element['label']
        return [ '<label for="%s">%s</label><br/>' % (element_id, label) ]
    %>
</%def>

<%def name="get_value(name, value='', attribute=True, offset=0)">
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
            attribute=False
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

        return [''.join(html_out)]
    %>
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
            attribute=False
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

        return [''.join(html_out)]
    %>
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
            attribute=False
        )
        if value:
            html_out.append(' value="%s"' % value)
        html_out.append(' />')
        html_out.append('<br />')

        return [''.join(html_out)]
    %>
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
            attribute=False
        ))
        # *AFTER
        # *REQUIRED
        html_out.append('</textarea><br />')

        return [''.join(html_out)]
    %>
</%def>

<%def name="Xtextarea(
    name=None,
    label=None,
    value=None,
    rows=None,
    cols=None,
    offset=0,

    clear=False,

    maxlength=64,
    
    textarea_class=None,
    style=None,
    before=None,
    after=None,
    highlight=False,
    required=True,
)">
<%
if value:
    value = None
elif not value and name:
    pass
    try:
        value = request.args[name][offset]
    except:
        pass

classes = []
if input_class:
    classes.append(textarea_class)
if highlight:
    classes.append('textarea-highlight')

html = [ '<div class="textarea">' ]
if name and label:
    html.append('<label for="%s">%s</label><br />' % (name, label))
if before:
    html.append(before)
html.append('<textarea name="%s"' % name)
if len(classes):
    html.append(' class="%s"' % ' '.join(classes))
if style:
    html.append(' style="%s"' % style)
if rows:
    html.append(' rows="%s"' % rows)
if cols:
    html.append(' cols="%s"' % cols)
if required:
    html.append(' required')
if maxlength:
    html.append(' maxlength="%s"' % maxlength)
html.append(' />')
if value:
    html.append(value)
html.append('</textarea>')
if required:
    html.append('<span class="input-required">*</span>')
if after:
    html.append(after)
html.append('</div>')

context.write(''.join(html))
%>
</%def>


## vim:ft=mako
