import base64
import json


def parse_echo_body(event):
    body_text = event.get("body") or "{}"
    if event.get("isBase64Encoded"):
        body_text = base64.b64decode(body_text).decode("utf-8")

    try:
        return json.loads(body_text)
    except json.JSONDecodeError as exc:
        raise ValueError("invalid json") from exc
