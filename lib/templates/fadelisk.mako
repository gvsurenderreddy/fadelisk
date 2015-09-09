<%
    try:
        next.body()
        return
    except:
        if site.conf.get('debug'):
            raise # Let twisted show its own traceback...
%>

## ...otherwise replace with a more-polite, less-informative message.
<%
    request.setResponseCode(500)
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <link rel="icon" href="/images/favicon.png" type="image/png">
        <title>Internal Server Error</title>
    </head>
    <body>
        <h1>Internal Server Error</h1>
        The web server has experienced an internal error, and
        cannot fulfill your request. We apologize for any
        inconvenience this may cause.
    </body>
</html>

