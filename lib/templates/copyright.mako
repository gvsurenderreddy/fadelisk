<%namespace name="organization" file="/organization.mako" />

<%!
    from datetime import date
%>

<%def name="copyright_declaration(year=0, name=None, use_group=False,
    copyright_word='&copy;')">
<%doc>
    year: year of first publication
    name: the name of the organization
    use_group: if true, prints a comma separated list of years instead
    copyright_word: Default is the circle-C symbol. "Copyright" and "Copr."
        are officially accepted.
</%doc>
<%
    if name == None:
        name = organization.organization_name()

    if not name:
        return ''

    this_year = date.today().year

    if not year:
        year = site.conf.get('first_publication', this_year)

    if year == this_year:
        cprt_year = year
    else:
	if use_group:
            cprt_year_group = [str(yr) for yr in range(year, this_year+1)]
            cprt_year = ', '.join(cprt_year_group)
        else:
            cprt_year = '%s-%s' % (year, this_year)
%>
<span id="copyright-declaration">
    ${copyright_word} ${cprt_year} ${name}
</span>
</%def>

