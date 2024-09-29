output "lambda_url" {
  value = aws_api_gateway_deployment.github_webhook_deployment.invoke_url
}
