output "varco_api_key_secret_arn" {
  description = "VARCO API key secret ARN."
  value       = aws_secretsmanager_secret.varco_api_key.arn
}

output "varco_api_key_secret_id" {
  description = "VARCO API key secret name (id)."
  value       = aws_secretsmanager_secret.varco_api_key.id
}

output "rds_admin_password_secret_arn" {
  description = "RDS master password secret ARN."
  value       = aws_secretsmanager_secret.rds_admin_password.arn
}

output "rds_admin_password_secret_id" {
  description = "RDS master password secret name (id) — RDS 모듈이 secret_version에 random_password 주입."
  value       = aws_secretsmanager_secret.rds_admin_password.id
}

output "proxy_credentials_secret_arn" {
  description = "Proxy credentials secret ARN."
  value       = aws_secretsmanager_secret.proxy_credentials.arn
}

output "all_secret_arns" {
  description = "전체 secret ARN 목록 — IAM 정책 ARN 한정에 사용."
  value = [
    aws_secretsmanager_secret.varco_api_key.arn,
    aws_secretsmanager_secret.rds_admin_password.arn,
    aws_secretsmanager_secret.proxy_credentials.arn,
  ]
}

output "detection_secret_arns" {
  description = "Detection EC2가 읽어야 할 secret ARN 목록 (varco + rds)."
  value = [
    aws_secretsmanager_secret.varco_api_key.arn,
    aws_secretsmanager_secret.rds_admin_password.arn,
  ]
}

output "api_secret_arns" {
  description = "API EC2가 읽어야 할 secret ARN 목록 (rds)."
  value = [
    aws_secretsmanager_secret.rds_admin_password.arn,
  ]
}
