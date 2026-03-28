output "api_endpoint" {
  description = "Base endpoint URL for HTTP API"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "hello_url" {
  description = "GET endpoint for hello"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/hello"
}

output "echo_url" {
  description = "POST endpoint for echo"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/echo"
}
