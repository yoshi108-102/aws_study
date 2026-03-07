import json
import os
from datetime import datetime, timezone


def lambda_handler(event, context):
    request_context = event.get("requestContext") or {}
    http_context = request_context.get("http") or {}
    method = http_context.get("method", "UNKNOWN")
    path = http_context.get("path", "/")
    timestamp = datetime.now(timezone.utc).isoformat()
    request_id = getattr(context, "aws_request_id", None)
    app_name = os.environ.get("APP_NAME", "unknown-app")

    response_body = {
        "message": "Hello from Terraform-managed Lambda",
        "app_name": app_name,
        "method": method,
        "path": path,
        "timestamp": timestamp,
        "request_id": request_id,
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "X-Debug-App-Name": app_name,
            "X-Debug-Method": method,
            "X-Debug-Path": path,
            "X-Debug-Timestamp": timestamp,
            "X-Debug-Request-Id": request_id or "unknown",
        },
        "body": json.dumps(response_body, ensure_ascii=False),
    }