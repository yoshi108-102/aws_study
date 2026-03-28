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
  region = var.aws_region
}

data "aws_lambda_layer_version" "powertools" {
  # AWS 公開の Powertools Layer を参照する。version を省略すると最新を取得する。
  layer_name = "arn:aws:lambda:${var.aws_region}:017000801446:layer:AWSLambdaPowertoolsPythonV3-python312-x86_64"
}

resource "random_id" "suffix" {
  byte_length = 3
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-role-${random_id.suffix.hex}"

  # Lambda がこのロールを利用するには、信頼ポリシーで lambda.amazonaws.com の AssumeRole 許可が必須。
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

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  # これがないと Lambda 実行時に CloudWatch Logs へ書き込めない。
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "api_handler" {
  function_name = "${var.project_name}-handler-${random_id.suffix.hex}"
  role          = aws_iam_role.lambda_exec.arn
  runtime       = "python3.12"
  # handler は "<module_path>.<function_name>" で、ZIP ルートからの Python モジュールパスを指定する。
  handler       = "app.handlers.api.lambda_handler"
  filename      = data.archive_file.lambda_zip.output_path
  # Powertools 本体は AWS 公開 Layer から読み込む。
  layers        = [data.aws_lambda_layer_version.powertools.arn]

  # ZIP の差分を検知して更新するため、source_code_hash は実運用でもほぼ必須。
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = 10
  memory_size = 128

  environment {
    variables = {
      POWERTOOLS_SERVICE_NAME = var.project_name
      POWERTOOLS_LOG_LEVEL    = var.powertools_log_level
    }
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-http-api-${random_id.suffix.hex}"
  protocol_type = "HTTP"

  cors_configuration {
    # APIGW 側で CORS を返す設定。未設定だとブラウザからの cross-origin 呼び出しで詰まりやすい。
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_integration" "lambda_proxy" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api_handler.invoke_arn
  # HTTP API + Lambda の標準イベントは 2.0。1.0 にすると event 構造が変わる。
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_hello" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /hello"
  # target は integrations/{integration_id} 固定フォーマット。
  target    = "integrations/${aws_apigatewayv2_integration.lambda_proxy.id}"
}

resource "aws_apigatewayv2_route" "post_echo" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /echo"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_proxy.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  # $default ステージは URL にステージ名が付かない。
  name        = "$default"
  # ルート変更時の手動デプロイ漏れを避けるため有効化。
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  # Lambda 側の Resource Policy 許可。これがないと APIGW 連携でも 500/権限エラーになる。
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
