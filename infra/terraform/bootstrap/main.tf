terraform {
  required_version = ">= 1.14, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# State backend bucket — created ONCE per env, then env directories
# (environments/dev, environments/prod) reference it via S3 backend config.
resource "aws_s3_bucket" "tfstate" {
  bucket = "tracker-tfstate-${var.env}"

  tags = {
    Name        = "tracker-tfstate-${var.env}"
    Environment = var.env
    Purpose     = "terraform-state-backend"
    ManagedBy   = "terraform-bootstrap"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 학생 계정 PIVOT — KMS CMK 생성 권한 부족 가정 → SSE-S3(AES256) 폴백.
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Terraform 1.10+ S3 native locking (use_lockfile) replaces DynamoDB lock table.
# DO NOT create a DynamoDB table — environments/{dev,prod}/backend.tf will set
# `use_lockfile = true` directly on the S3 backend.
