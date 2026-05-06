terraform {
  required_version = ">= 1.14, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

##
# Secrets — placeholder만 정의. 실제 값은 ops 1회 콘솔/CLI 주입:
#   - varco_api_key      : VARCO LLM API 발급키
#   - proxy_credentials  : 프록시 서비스(IPRoyal/ThorData) 자격 증명
#
# 평문 값은 절대 Terraform 변수/tfvars에 두지 않는다 (NFR5, deferred-work 안티패턴).
#
# RDS 마스터 비밀번호는 본 모듈에서 관리하지 않음:
#   - RDS 모듈에서 `manage_master_user_password = true` 옵션으로 RDS가 자동 생성/관리
#   - 이전 `random_password` + `aws_secretsmanager_secret_version` 패턴은 tfstate에
#     평문 비밀번호 노출 risk가 있어 제거됨 (보안 점검 fix)
#   - IAM 정책은 module.rds.master_user_secret_arn을 별도 참조
#
# KMS — AWS-managed `alias/aws/secretsmanager` 자동 사용 (KMS CMK 권한 부족 가정).
##

resource "aws_secretsmanager_secret" "varco_api_key" {
  name                    = "${var.name_prefix}/varco-api-key"
  description             = "VARCO LLM API key — 값은 Console 또는 ops 스크립트로 1회 주입"
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(var.tags, { Module = "secrets", Purpose = "varco-api-key" })
}

resource "aws_secretsmanager_secret" "proxy_credentials" {
  name                    = "${var.name_prefix}/proxy-credentials"
  description             = "Proxy(IPRoyal/ThorData) credentials — 값은 Console 또는 ops 스크립트로 1회 주입"
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(var.tags, { Module = "secrets", Purpose = "proxy-credentials" })
}
