import json

from aws_lambda_powertools import Logger
from aws_lambda_powertools.logging import correlation_paths

from app.usecases.echo import parse_echo_body
from app.usecases.hello import build_hello_payload


logger = Logger()


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "content-type": "application/json"
        },
        "body": json.dumps(body, ensure_ascii=False)
    }


@logger.inject_lambda_context(
    log_event=False,
    correlation_id_path=correlation_paths.API_GATEWAY_HTTP,
    clear_state=True,
)
def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    path = event.get("rawPath", "")

    logger.append_keys(method=method, path=path)
    logger.info("handler_start")

    if method == "GET" and path.endswith("/hello"):
        logger.info("route_matched_hello")
        response = _response(200, build_hello_payload(method=method, path=path))
        logger.info("handler_end", extra={"status_code": 200})
        return response

    if method == "POST" and path.endswith("/echo"):
        logger.info("route_matched_echo")
        try:
            body = parse_echo_body(event)
        except ValueError:
            logger.warning("echo_body_parse_failed")
            return _response(400, {"error": "invalid json"})

        logger.info("echo_body_parse_success")
        response = _response(200, {"received": body})
        logger.info("handler_end", extra={"status_code": 200})
        return response

    logger.info("handler_not_found")
    return _response(404, {"error": "not found"})
