output "crawler_instance_profile_name" {
  description = "Crawler EC2 instance profile name."
  value       = aws_iam_instance_profile.crawler.name
}

output "detection_instance_profile_name" {
  description = "Detection EC2 instance profile name."
  value       = aws_iam_instance_profile.detection.name
}

output "api_instance_profile_name" {
  description = "API EC2 instance profile name."
  value       = aws_iam_instance_profile.api.name
}

output "crawler_role_arn" {
  description = "Crawler EC2 role ARN."
  value       = aws_iam_role.crawler.arn
}

output "detection_role_arn" {
  description = "Detection EC2 role ARN."
  value       = aws_iam_role.detection.arn
}

output "api_role_arn" {
  description = "API EC2 role ARN."
  value       = aws_iam_role.api.arn
}

output "github_actions_role_arn" {
  description = "GitHub Actions Terraform IAM role ARN — workflow의 role-to-assume에 사용."
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "GitHub OIDC provider ARN (생성한 경우 또는 기존 ARN)."
  value       = local.oidc_provider_arn
}
