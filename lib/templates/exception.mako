
<%!
    import traceback
    import mako
    import string

    try:
        from mako.ext.pygmentplugin import syntax_highlight, \
            pygments_html_formatter
    except:
        pygments_html_formatter = None
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
        request_data['flags']['no_title'] = True
    %>
    <h1>Internal Server Error</h1>
    The server encountered an error while rendering the page you requested.
</%def>

<%def name="fadelisk_exception()">
    <%
        request_data['flags']['no_title'] = True
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
    %>
    <h2>Location in Template</h2>
    <div class="code-sample">
        <div class="location">${filename}, line ${tback.lineno}:</div>
        <div class="container">
        % for index in range(first_line, last_line):
            ${code_line(lines[index], index+1, tback.lineno, language="mako")}
        % endfor
        </div>
    </div>
</%def>

<%def name="mako_stack_trace(tback)">
    <h2>Mako Stack Trace</h2>
    <div class="fadelisk-stack-trace">
    % for (filename, lineno, function, line) in tback.reverse_traceback:
        <%
            if not line:
                continue

            if pygments_html_formatter:
                pygments_html_formatter.linenostart = lineno
        %>
        <div class="location">${filename}, line ${lineno}:</div>
        <div class="container">
            ${code_line(line, lineno, filename=filename)}
        </div>
    % endfor
    </div>
</%def>

<%def name="code_line(code, line, error_line=0, filename='', language=None)">
    % if pygments_html_formatter:
        <%
            pygments_html_formatter.linenostart = line
            if line == error_line:
                pygments_html_formatter.cssclass += ' error'
        %>
        ${string.rstrip(code) | syntax_highlight(filename, language=language)}
        <%
            if line == error_line:
                pygments_html_formatter.cssclass = (
                        pygments_html_formatter.cssclass.split()[0])
        %>
    % else:
        <%
            error_class = 'error ' if line == error_line else ''
        %>
        <table class="syntax-highlightedtable">
            <tr>
                <td class="linenos">
                    <div class="linenodiv">
                        <pre>${line}</pre>
                    </div>
                </td>
                <td class="code">
                    <div class="${error_class}syntax-highlighted">
                        <pre>${code | h}</pre>
                    </div>
                </td>
            </tr>
        </table>
    % endif
</%def>

<%def name="python_traceback()">
    <h2>Python Traceback</h2>
    <div class="python-traceback">
    <pre>${traceback.format_exc()}</pre>
    </div>
</%def>

<%def name="fadelisk_exception_style()">
    <style>
        % if pygments_html_formatter:
            ${pygments_html_formatter.get_style_defs()}
        % endif
        #fadelisk-exception .location {
            padding: .2em .4em;
            background: rgba(0, 0, 0, .6);
            color: #dde;
            border-radius: .2em .2em 0 0;
        }
        #fadelisk-exception .container,
        #fadelisk-exception .python-traceback {
            background-color: rgba(240, 240, 240, .7);
            border-radius: 0 0 .2em .2em;
        }
        #fadelisk-exception .fadelisk-stack-trace .container {
            margin-bottom: 1em;
        }
        #fadelisk-exception .python-traceback {
            border-radius: .2em;
            padding: .5em 1em;
        }
        #fadelisk-exception pre { margin: 0; }
        #fadelisk-exception .syntax-highlighted  {
            background: none;
            padding: 0 .2em;
        }
        #fadelisk-exception .linenos {
            background: rgba(0, 0, 0, .1);
            min-width: 2.5em;
            text-align: right;
            padding: 2px .3em 2px 2px;
        }
        #fadelisk-exception .code {
            background-color: rgba(255, 255, 255, .7);
            width: 100%;
        }
        #fadelisk-exception .error {
            background-color: rgba(255, 0, 0, .2);
        }
    </style>
</%def>

