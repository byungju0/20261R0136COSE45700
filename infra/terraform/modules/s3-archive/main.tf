terraform {
  required_version = ">= 1.14, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  bucket_name = "${var.bucket_name_prefix}-${var.env}-${random_id.suffix.hex}"
}

resource "aws_s3_bucket" "archive" {
  bucket = local.bucket_name

  tags = merge(var.tags, {
    Name    = local.bucket_name
    Module  = "s3-archive"
    Purpose = "raw-html-archive"
  })
}

resource "aws_s3_bucket_public_access_block" "archive" {
  bucket = aws_s3_bucket.archive.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "archive" {
  bucket = aws_s3_bucket.archive.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 학생 계정 PIVOT — KMS CMK 생성 권한 부족 가정 → SSE-S3(AES256) 폴백.
# AWS-managed S3 키로 자동 암호화되며 비용 0, 권한 요구 X.
resource "aws_s3_bucket_server_side_encryption_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle — 90일 IA, 365일 삭제 (예산 보호 + Story 1.4 데이터 보관 정책)
resource "aws_s3_bucket_lifecycle_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id

  rule {
    id     = "archive-tiering-and-expiration"
    status = "Enabled"

    filter {}

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Access logging — Checkov CKV_AWS_18
# CloudTrail S3 버킷에 access log 적재 (Task 8 모듈이 이 버킷 ARN을 받아 같은 패턴 처리)
resource "aws_s3_bucket_logging" "archive" {
  count = var.access_log_bucket_id != "" ? 1 : 0

  bucket        = aws_s3_bucket.archive.id
  target_bucket = var.access_log_bucket_id
  target_prefix = "s3-access-logs/${local.bucket_name}/"
}

##
# Bucket policy — Crawler IAM Role의 PutObject만 허용, 그 외 모든 Principal Deny.
# 외부 접근(0.0.0.0/0)을 명시적으로 거부하면 Checkov S3 룰 가드가 한 겹 더 추가된다.
##
data "aws_iam_policy_document" "archive" {
  # Crawler PutObject 허용
  statement {
    sid    = "CrawlerPutOnly"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.crawler_role_arn]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:AbortMultipartUpload",
    ]

    resources = ["${aws_s3_bucket.archive.arn}/*"]
  }

  # Crawler ListBucket 허용 (선택적 — 기록 검증)
  statement {
    sid    = "CrawlerListBucket"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.crawler_role_arn]
    }

    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.archive.arn]
  }

  # 비-TLS 접근 거부 — Checkov CKV_AWS_19 패밀리
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.archive.arn,
      "${aws_s3_bucket.archive.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "archive" {
  bucket = aws_s3_bucket.archive.id
  policy = data.aws_iam_policy_document.archive.json

  depends_on = [aws_s3_bucket_public_access_block.archive]
}
