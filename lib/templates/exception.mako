
<%!
    import traceback
    import mako
    import string
%>

<%def name="catch(func)">
    <%
        try:
            return capture(func)
        except:
            if site.conf.get('debug'):
                return capture(fadelisk_exception)
            else:
                return capture(internal_server_error)
    %>
</%def>

<%def name="internal_server_error()">
    <%
        request.setResponseCode(500)
        request_data['flags']['no_title_in_layout'] = True
    %>
    <h1>Internal Server Error</h1>
    The server encountered an error while rendering the page you requested.
</%def>

<%def name="fadelisk_exception()">
    <%
        request_data['flags']['no_title_in_layout'] = True
        tback = mako.exceptions.RichTraceback()
    %>
    <h1>${tback.errorname}: ${tback.message|h}</h1>
    ${fadelisk_exception_style()}

    <div id="fadelisk-exception">
        ${code_sample(tback)}
        ${mako_stack_trace(tback)}
        ${python_traceback()}
    </div>
</%def>

<%def name="code_sample(tback)">
    <%
        if tback.source:
            lines = tback.source.split('\n')
        else:
            return ''

        filename = tback.records[-1][4]
        first_line = max(0, tback.lineno-4)
        last_line = min(len(lines), tback.lineno+5)

        code = []
        for line_num in range(first_line, last_line):
            code.append({'line-number': line_num+1, 'code': lines[line_num]})
    %>
    <h2>Location in Template</h2>
    ${code_table(code, error_line=tback.lineno, filename=filename)}
</%def>

<%def name="mako_stack_trace(tback)">
    <h2>Mako Stack Trace</h2>
    <div class="fadelisk-stack-trace">
    % for (filename, line_num, func, code) in tback.reverse_traceback:
        ${code_table({'line-number': line_num, 'code': code }, filename)}
    % endfor
    </div>
</%def>

<%def name="code_table(code, filename='', error_line=0)">
    <%
        if isinstance(code, dict):
            code = [code]

        if error_line:
            line_indication = ', line %s' % error_line
        else:
            line_indication = ''

        if filename.endswith('.html') or filename.endswith('.htm'):
            language = 'mako'
        elif filename.endswith('.py'):
            language = 'python'
        else:
            language = ''
        if language:
            language = ' class="language-' + language + '"'
    %>

    % if filename:
    <div class="header">
        ${filename}${line_indication}:
    </div>
    % endif

    <table>
        % for line in code:
            <% line_num = line['line-number'] %>
            <tr>
                <td class="line-number">
                    ${line_num}
                </td>
                <td class="code${' error' if error_line == line_num else ''}">
                    <pre><code${language}>${line['code'] |h}</code></pre>
                </td>
            </tr>
        % endfor
    </table>
</%def>

<%def name="python_traceback()">
    <h2>Python Traceback</h2>
    <div class="python-traceback">
    <pre>${traceback.format_exc()}</pre>
    </div>
</%def>

<%def name="fadelisk_exception_style()">
    <style>
        #fadelisk-exception pre[class*="language-"],
        .token.operator {
            background: none;
        }

        #fadelisk-exception table,
        #fadelisk-exception .python-traceback
        {
            background-color: hsla(0, 0%, 100%, .8);
            width: 100%;
            margin-bottom: 1em;
            border-radius: .2em;
        }

        #fadelisk-exception .python-traceback {
            padding: .5em .7em;
        }

        #fadelisk-exception pre {
            margin: 0; padding: 0;
        }

        #fadelisk-exception .header {
            padding: .2em .4em;
            background: rgba(0, 0, 0, .6);
            color: #dde;
            border-radius: .2em .2em 0 0;
        }

        #fadelisk-exception td {
            border-radius: .2em;
        }

        #fadelisk-exception .line-number {
            width: 3em;
            text-align: right;
            padding-right: .2em;
            background-color: hsla(0, 0%, 0%, .1);
        }

        #fadelisk-exception .code {
            padding-left: .5em;
        }
    </style>
</%def>

