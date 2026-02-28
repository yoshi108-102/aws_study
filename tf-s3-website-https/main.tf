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

# -------------------------------------------------------
# Provider
# -------------------------------------------------------
provider "aws" {
  region = "ap-northeast-1" # 東京
}

# -------------------------------------------------------
# ランダムサフィックス
# -------------------------------------------------------
resource "random_id" "suffix" {
  byte_length = 4
}

# -------------------------------------------------------
# S3 バケット（非公開 ― CloudFront OAC 経由でのみアクセス）
# -------------------------------------------------------
resource "aws_s3_bucket" "website" {
  bucket = "tf-s3-website-https-${random_id.suffix.hex}"
}

# パブリックアクセスを完全にブロック
resource "aws_s3_bucket_public_access_block" "website" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront OAC からのアクセスのみ許可するバケットポリシー
resource "aws_s3_bucket_policy" "website" {
  depends_on = [aws_s3_bucket_public_access_block.website]

  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      }
    ]
  })
}

# -------------------------------------------------------
# CloudFront
# -------------------------------------------------------

# Origin Access Control（OAC）— S3 へのアクセス制御
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "oac-tf-s3-website-https-${random_id.suffix.hex}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "tf-s3-website-https"

  # ── オリジン（S3）──
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  # ── デフォルトキャッシュ動作 ──
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # ── カスタムエラーレスポンス ──
  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/error.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/error.html"
  }

  # ── 地理的制限（なし）──
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ── SSL/TLS（CloudFront デフォルト証明書）──
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "tf-s3-website-https"
  }
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
  description = "S3 バケット名"
  value       = aws_s3_bucket.website.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront ディストリビューション ID"
  value       = aws_cloudfront_distribution.website.id
}

output "website_url" {
  description = "HTTPS ウェブサイト URL"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "s3_direct_url" {
  description = "S3 直アクセス URL（403 AccessDenied になるはず）"
  value       = "https://${aws_s3_bucket.website.bucket_regional_domain_name}/index.html"
}
