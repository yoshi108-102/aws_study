# Terraform 本体と利用するプロバイダのバージョン条件を定義する。
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

# AWS プロバイダを指定リージョンで有効化する。
provider "aws" {
  region = var.aws_region
}

# リソース名の衝突を避けるためのランダムサフィックスを生成する。
resource "random_id" "suffix" {
  byte_length = 3
}

# Lambda が実行時に引き受ける IAM ロールを作成する。
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-role-${random_id.suffix.hex}"

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

# Lambda ロールに CloudWatch Logs へ出力する基本権限を付与する。
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda コードを ZIP 化してデプロイ可能なアーティファクトを作成する。
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

# API リクエストを処理する Lambda 関数本体を作成する。
resource "aws_lambda_function" "api_handler" {
  function_name = "${var.project_name}-handler-${random_id.suffix.hex}"
  role          = aws_iam_role.lambda_exec.arn
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  filename      = data.archive_file.lambda_zip.output_path

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = 10
  memory_size = 128
}

# HTTP API 本体を作成し、最小の CORS 設定を有効化する。
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-http-api-${random_id.suffix.hex}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }
}

# API Gateway から Lambda へプロキシ統合する接続を作成する。
resource "aws_apigatewayv2_integration" "lambda_proxy" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api_handler.invoke_arn
  payload_format_version = "2.0"
}

# GET /hello を Lambda 統合へルーティングする。
resource "aws_apigatewayv2_route" "get_hello" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_proxy.id}"
}

# POST /echo を Lambda 統合へルーティングする。
resource "aws_apigatewayv2_route" "post_echo" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /echo"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_proxy.id}"
}

# デフォルトステージを自動デプロイで公開する。
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# API Gateway から Lambda を呼び出せるよう実行許可を付与する。
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
