terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1" # 東京
}

resource "random_id" "suffix" {
  byte_length = 4
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "tf-lambda-hello-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/tf-lambda-hello-${random_id.suffix.hex}"
  retention_in_days = 7
}

resource "aws_lambda_function" "hello" {
  function_name = "tf-lambda-hello-${random_id.suffix.hex}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  timeout       = 10

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  logging_config {
    log_format = "Text"
    log_group = aws_cloudwatch_log_group.lambda.name
  }

  environment {
    variables = {
      APP_NAME = "tf-lambda-hello"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.basic_execution,
    aws_cloudwatch_log_group.lambda,
  ]
}

resource "aws_lambda_function_url" "hello" {
  function_name      = aws_lambda_function.hello.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "function_url_public" {
  statement_id           = "AllowPublicFunctionUrlInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.hello.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

output "lambda_function_name" {
  description = "Lambda 関数名"
  value       = aws_lambda_function.hello.function_name
}

output "function_url" {
  description = "Lambda Function URL"
  value       = aws_lambda_function_url.hello.function_url
}

output "cloudwatch_log_group" {
  description = "CloudWatch Logs のロググループ"
  value       = aws_cloudwatch_log_group.lambda.name
}