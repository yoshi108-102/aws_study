terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
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

# -------------------------------------------------------
# S3バケット（静的ウェブサイトホスティング用）
# -------------------------------------------------------
resource "aws_s3_bucket" "website" {
  bucket = "tf-s3-website-${random_id.suffix.hex}"
}

# 静的ウェブサイトホスティング設定
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# 公開アクセスブロックを解除（静的ウェブサイトには必要）
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# バケットポリシー：パブリック読み取りを許可
resource "aws_s3_bucket_policy" "website" {
  # public_access_block を先に解除しないとエラーになる
  depends_on = [aws_s3_bucket_public_access_block.website]

  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

# -------------------------------------------------------
# サイトファイルのアップロード（site/ ディレクトリ以下）
# -------------------------------------------------------
locals {
  site_dir = "${path.module}/../site"

  # 拡張子 → Content-Type のマッピング
  mime_types = {
    "html" = "text/html; charset=utf-8"
    "css"  = "text/css; charset=utf-8"
    "js"   = "application/javascript; charset=utf-8"
    "json" = "application/json"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "svg"  = "image/svg+xml"
    "ico"  = "image/x-icon"
  }
}

resource "aws_s3_object" "site_files" {
  for_each = fileset(local.site_dir, "**/*")

  bucket = aws_s3_bucket.website.bucket
  key    = each.value
  source = "${local.site_dir}/${each.value}"
  etag   = filemd5("${local.site_dir}/${each.value}")

  content_type = lookup(
    local.mime_types,
    split(".", each.value)[length(split(".", each.value)) - 1],
    "application/octet-stream"
  )
}

# -------------------------------------------------------
# Outputs
# -------------------------------------------------------
output "bucket_name" {
  description = "S3バケット名"
  value       = aws_s3_bucket.website.bucket
}

output "website_endpoint" {
  description = "静的ウェブサイトのURL（http）"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}
