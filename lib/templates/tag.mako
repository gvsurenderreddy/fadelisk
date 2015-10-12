<%doc>
    TAG: XHTML-Compliant Tag Builder
</%doc>

<%!
    from xml.sax.saxutils import quoteattr
%>

<%def name="build_tag(name, attribs={}, content=None, void=True)"
    filter="n,trim">
    <%
        items = ['<%s' % name]
        if attribs:
            items.append(' ')
            items.append(build_attribs(attribs))
        if content == None:
            if void:
                items.append(' /')
        else:
            items.append('>%s</%s' % (content, name))
        items.append('>')
        return ''.join(items)
    %>
</%def>

<%def name="build_attribs(attribs)"
    filter="n,trim">
    <%
        items = []
        for attrib, value in attribs.iteritems():
            if value is None:
                continue
            if not isinstance(value, unicode):
                value = unicode(value)
            if len(value):
                items.append('%s=%s' % (attrib, quoteattr(value)))
        return ' '.join(items)
    %>
</%def>

