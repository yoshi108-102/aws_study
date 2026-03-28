import json

from app.usecases.echo import parse_echo_body
from app.usecases.hello import build_hello_payload


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "content-type": "application/json"
        },
        "body": json.dumps(body, ensure_ascii=False)
    }


def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    path = event.get("rawPath", "")

    if method == "GET" and path.endswith("/hello"):
        print("Received GET request to /hello")
        return _response(200, build_hello_payload(method=method, path=path))

    if method == "POST" and path.endswith("/echo"):
        try:
            body = parse_echo_body(event)
        except ValueError:
            return _response(400, {"error": "invalid json"})

        return _response(200, {"received": body})

    return _response(404, {"error": "not found"})
