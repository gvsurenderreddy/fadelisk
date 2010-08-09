## <%page cached="False" cache_type="memory"/>

<%!
    # import fadelisk
%>

<%namespace name="menu" file="/menu.mako" inheritable="True" />
<%namespace name="page_title" file="/page_title.mako" inheritable="True" />

${next.body(**context.kwargs)}

