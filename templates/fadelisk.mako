## <%page cached="False" cache_type="memory"/>

<%!
    # import fadelisk
%>

##<%namespace name="menu" file="/example_global.mako" inheritable="True" />

${next.body(**context.kwargs)}

