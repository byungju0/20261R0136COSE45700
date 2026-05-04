terraform {
  required_version = ">= 1.14, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

data "aws_partition" "current" {}

locals {
  partition = data.aws_partition.current.partition
}

##
# EC2 trust policy (assume role by ec2.amazonaws.com)
##
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

##
# Crawler EC2 role — SSM + S3 PutObject (특정 버킷·prefix 한정)
##
resource "aws_iam_role" "crawler" {
  name               = "${var.name_prefix}-ec2-crawler"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
  tags               = merge(var.tags, { Service = "crawler" })
}

resource "aws_iam_role_policy_attachment" "crawler_ssm" {
  role       = aws_iam_role.crawler.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "crawler_s3" {
  statement {
    sid    = "S3PutToArchive"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:AbortMultipartUpload",
    ]
    resources = ["${var.archive_bucket_arn}/*"]
  }

  statement {
    sid    = "S3ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [var.archive_bucket_arn]
  }
}

resource "aws_iam_policy" "crawler_s3" {
  name   = "${var.name_prefix}-ec2-crawler-s3"
  policy = data.aws_iam_policy_document.crawler_s3.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "crawler_s3" {
  role       = aws_iam_role.crawler.name
  policy_arn = aws_iam_policy.crawler_s3.arn
}

resource "aws_iam_instance_profile" "crawler" {
  name = "${var.name_prefix}-ec2-crawler"
  role = aws_iam_role.crawler.name
  tags = var.tags
}

##
# Detection EC2 role — SSM + Secrets Manager Get (varco_api_key)
##
resource "aws_iam_role" "detection" {
  name               = "${var.name_prefix}-ec2-detection"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
  tags               = merge(var.tags, { Service = "detection" })
}

resource "aws_iam_role_policy_attachment" "detection_ssm" {
  role       = aws_iam_role.detection.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "detection_secrets" {
  statement {
    sid    = "GetVarcoAndRdsSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = var.detection_secret_arns
  }
}

resource "aws_iam_policy" "detection_secrets" {
  name   = "${var.name_prefix}-ec2-detection-secrets"
  policy = data.aws_iam_policy_document.detection_secrets.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "detection_secrets" {
  role       = aws_iam_role.detection.name
  policy_arn = aws_iam_policy.detection_secrets.arn
}

resource "aws_iam_instance_profile" "detection" {
  name = "${var.name_prefix}-ec2-detection"
  role = aws_iam_role.detection.name
  tags = var.tags
}

##
# API EC2 role — SSM + Secrets Manager Get (rds_admin_password)
##
resource "aws_iam_role" "api" {
  name               = "${var.name_prefix}-ec2-api"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
  tags               = merge(var.tags, { Service = "api" })
}

resource "aws_iam_role_policy_attachment" "api_ssm" {
  role       = aws_iam_role.api.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "api_secrets" {
  statement {
    sid    = "GetApiSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = var.api_secret_arns
  }
}

resource "aws_iam_policy" "api_secrets" {
  name   = "${var.name_prefix}-ec2-api-secrets"
  policy = data.aws_iam_policy_document.api_secrets.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "api_secrets" {
  role       = aws_iam_role.api.name
  policy_arn = aws_iam_policy.api_secrets.arn
}

resource "aws_iam_instance_profile" "api" {
  name = "${var.name_prefix}-ec2-api"
  role = aws_iam_role.api.name
  tags = var.tags
}

# NOTE: GitHub Actions OIDC Provider + GHA Terraform Role 자원은 PIVOT 정리로 제거됨.
# CI는 정적 가드만 실행하고 plan/apply는 사용자가 CloudShell에서 수동 실행하므로
# OIDC + Role 자체가 불필요. 졸업 후 production CI 도입 시 git history(`bd172d9`
# 또는 `3b98a13`)에서 다음 자원 + 정책 + 변수/outputs 함께 복원:
#   - aws_iam_openid_connect_provider.github (count 토글)
#   - aws_iam_role.github_actions + assume_role_policy(OIDC trust)
#   - aws_iam_policy.github_actions_terraform + attachment
#   - data.aws_iam_policy_document.github_actions_trust / .github_actions_terraform
#   - locals.oidc_provider_arn
#   - variables: tfstate_bucket_name, create_oidc_provider,
#                existing_oidc_provider_arn, github_actions_sub_patterns
#   - outputs: github_actions_role_arn, oidc_provider_arn
