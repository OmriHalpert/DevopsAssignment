provider "aws" {
  region = var.region
}

# IAM

resource "aws_iam_role" "lambda_exec" {
  name        = "lambda_exec_role"
  description = "IAM Role for Lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "IAM policy for Lambda to access CloudWatch logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lambda_function_name}"
        Effect   = "Allow"
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lambda_function_name}:log-stream:*"
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_exec.name
}

# Lambda

resource "aws_lambda_function" "lambda" {
  function_name    = var.lambda_function_name
  description      = "Lambda for GitHub Webhook"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256(var.lambda_zip_file)
  filename         = var.lambda_zip_file
  depends_on       = [aws_cloudwatch_log_group.lambda_log_group]
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.github_webhook_api.id}/${var.stage}/${aws_api_gateway_method.webhook_post.http_method}${aws_api_gateway_resource.github_webhook.path}"
}

# API Gateway

resource "aws_api_gateway_rest_api" "github_webhook_api" {
  name        = "GitHub Webhook API"
  description = "API Gateway for GitHub Webhook"
}

resource "aws_api_gateway_resource" "github_webhook" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  parent_id   = aws_api_gateway_rest_api.github_webhook_api.root_resource_id
  path_part   = "webhook"
}

resource "aws_api_gateway_method" "webhook_post" {
  rest_api_id   = aws_api_gateway_rest_api.github_webhook_api.id
  resource_id   = aws_api_gateway_resource.github_webhook.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.github_webhook_api.id
  resource_id             = aws_api_gateway_resource.github_webhook.id
  http_method             = aws_api_gateway_method.webhook_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "github_webhook_deployment" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  stage_name  = var.stage
  depends_on  = [aws_api_gateway_integration.lambda_integration]
}

# CloudWatch + Data

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

data "archive_file" "archiver" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

data "aws_caller_identity" "current" {}