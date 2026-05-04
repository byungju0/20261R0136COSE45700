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

##
# GitHub OIDC Provider (계정당 1개 — multiple env에서 동일 provider 공유)
# environments/dev에서만 생성, prod는 data lookup으로 참조하는 패턴 권장.
# 단순화를 위해 module에서 변수로 토글: create_oidc_provider=true 시에만 생성.
##
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS provider v6 + GitHub IdP는 AWS-trusted CA 라이브러리로 검증 → thumbprint는
  # retained but not used. AWS 공식 가이드에 따라 thumbprint_list는 placeholder만 유지.
  # 회전 영향 없음 (AWS가 GitHub OIDC 인증을 자체 CA로 처리).
  # 참고: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]

  tags = var.tags
}

# OIDC provider ARN (생성한 경우 또는 기존 ARN 변수)
locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
}

##
# GitHub Actions IAM Role (env별 1개 — dev / prod)
# trust 조건:
#   - dev : repo:{owner}/{repo}:ref:refs/heads/main 머지 시 자동 apply
#   - prod: repo:{owner}/{repo}:environment:prod 보호 규칙 + 수동 승인
##
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.github_actions_sub_patterns
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.name_prefix}-gha-terraform"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = merge(var.tags, { Purpose = "github-actions-terraform" })
}

# GHA Terraform Role 권한 — 학생 계정 PIVOT으로 CloudTrail/KMS CMK/Budgets 액션 제거.
# (본 스토리에서 해당 자원을 만들지 않으므로 권한 불필요)
data "aws_iam_policy_document" "github_actions_terraform" {
  # plan 단계 — 본 스토리 자원 read
  statement {
    sid    = "ReadAllForPlan"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "rds:Describe*",
      "rds:ListTagsForResource",
      "s3:GetBucket*",
      "s3:ListBucket*",
      "s3:ListAllMyBuckets",
      "iam:GetRole",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListRoles",
      "iam:ListPolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:GetInstanceProfile",
      "iam:GetOpenIDConnectProvider",
      "logs:Describe*",
      "secretsmanager:Describe*",
      "secretsmanager:ListSecrets",
    ]
    resources = ["*"]
  }

  # State backend 액세스 — bootstrap이 만든 버킷
  statement {
    sid    = "TfStateBucketRW"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketVersioning",
    ]
    resources = [
      "arn:${local.partition}:s3:::${var.tfstate_bucket_name}",
      "arn:${local.partition}:s3:::${var.tfstate_bucket_name}/*",
    ]
  }

  # apply 단계 — 본 스토리 PIVOT 후 모듈이 다루는 리소스만 mutate.
  # CloudTrail/KMS CMK/Budgets는 학생 계정 권한 부족 가정으로 제거됨.
  statement {
    sid    = "MutateInfraResources"
    effect = "Allow"
    actions = [
      "ec2:*",
      "rds:*",
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutBucket*",
      "s3:GetBucketTagging",
      "s3:PutObject",
      "s3:DeleteObject",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:PassRole",
      "iam:TagRole",
      "iam:TagPolicy",
      "iam:UntagRole",
      "iam:UntagPolicy",
      "logs:Create*",
      "logs:Put*",
      "logs:DeleteLogGroup",
      "logs:TagLogGroup",
      "secretsmanager:CreateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:UpdateSecret",
      "secretsmanager:TagResource",
      "secretsmanager:UntagResource",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions_terraform" {
  name   = "${var.name_prefix}-gha-terraform"
  policy = data.aws_iam_policy_document.github_actions_terraform.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_terraform.arn
}
