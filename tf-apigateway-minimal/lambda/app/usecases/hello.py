def build_hello_payload(method, path):
    return {
        "message": "hello apigateway",
        "path": path,
        "method": method,
    }
