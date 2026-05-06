output "varco_api_key_secret_arn" {
  description = "VARCO API key secret ARN."
  value       = aws_secretsmanager_secret.varco_api_key.arn
}

output "varco_api_key_secret_id" {
  description = "VARCO API key secret name (id)."
  value       = aws_secretsmanager_secret.varco_api_key.id
}

output "proxy_credentials_secret_arn" {
  description = "Proxy credentials secret ARN."
  value       = aws_secretsmanager_secret.proxy_credentials.arn
}

# NOTE: rds_admin_password는 본 모듈에서 관리하지 않음 (보안 fix).
# RDS 모듈의 manage_master_user_password=true가 자동 생성한 secret의 ARN을
# environments에서 module.rds.master_user_secret_arn으로 직접 참조 + IAM 정책에 주입.
