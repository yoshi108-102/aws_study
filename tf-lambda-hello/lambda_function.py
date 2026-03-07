import json
import os
from datetime import datetime, timezone


def lambda_handler(event, context):
    request_context = event.get("requestContext") or {}
    http_context = request_context.get("http") or {}

    response_body = {
        "message": "Hello from Terraform-managed Lambda",
        "app_name": os.environ.get("APP_NAME", "unknown-app"),
        "method": http_context.get("method", "UNKNOWN"),
        "path": http_context.get("path", "/"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "request_id": getattr(context, "aws_request_id", None),
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body, ensure_ascii=False),
    }