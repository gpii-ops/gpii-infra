def on_failure(request_type, name, response_time, exception, **kwargs):
    print("Request: %s %s" % (request_type, name))
    if exception.request is not None:
        print("URL: %s" % (exception.request.url))
    print("Exception: %s" % (exception))
    if exception.response is not None:
        print("Code: %s" % (exception.response.status_code))
        print("Headers: %s" % (exception.response.headers))
        print("Content: %s" % (exception.response.content))
