<%!
    from datetime import date
%>


<%def name="declaration(year, name, use_group=False, copyright_word='&copy;')">
<%doc>
    year: year of first publication
    name: the name of the organization
    use_group: if true, prints a comma separated list of years instead
    copyright_word: Default is the circle-C symbol. "Copyright" and "Copr."
        are officially accepted.
</%doc>
<%
    this_year = date.today().year
    cprt_year = year
    if year != this_year:
	if use_group:
            cprt_year_group = [str(yr) for yr in range(year, this_year+1)]
            cprt_year = ', '.join(cprt_year_group)
        else:
            cprt_year = '%s-%s' % (year, this_year)
%>

${copyright_word} ${cprt_year} ${name}

</%def>

