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

resource "aws_s3_bucket" "this" {
  bucket = "tf-s3-try-${random_id.suffix.hex}"
}

# 公開ブロック（事故防止）
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# バージョン管理
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_object" "memo" {
  for_each = fileset("${path.module}/../memo", "**/*.md")

  bucket = aws_s3_bucket.this.bucket

  # S3上のキー（=パス）。memo/ の下に同じ構造で置く
  key = "memo/${each.value}"

  # ローカルファイルの実体
  source = "${path.module}/../memo/${each.value}"

  content_type = "text/markdown; charset=utf-8"

  # ファイル変更を確実に検知して更新させる
  etag = filemd5("${path.module}/../memo/${each.value}")
}

output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}