import base64
import json


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
        return _response(
            200,
            {
                "message": "hello apigateway",
                "path": path,
                "method": method
            }
        )

    if method == "POST" and path.endswith("/echo"):
        body_text = event.get("body") or "{}"
        if event.get("isBase64Encoded"):
            body_text = base64.b64decode(body_text).decode("utf-8")

        try:
            body = json.loads(body_text)
        except json.JSONDecodeError:
            return _response(400, {"error": "invalid json"})

        return _response(200, {"received": body})

    return _response(404, {"error": "not found"})
