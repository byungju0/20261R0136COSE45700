variable "name_prefix" {
  description = "IAM resource name prefix (e.g., tracker-dev)."
  type        = string
}

variable "archive_bucket_arn" {
  description = "S3 archive bucket ARN — Crawler PutObject target."
  type        = string
}

variable "detection_secret_arns" {
  description = "Secrets Manager ARNs Detection EC2 may read (varco_api_key, rds_admin_password)."
  type        = list(string)
}

variable "api_secret_arns" {
  description = "Secrets Manager ARNs API EC2 may read (rds_admin_password)."
  type        = list(string)
}

variable "tfstate_bucket_name" {
  description = "Bootstrap-created tfstate bucket name (for GitHub Actions backend access)."
  type        = string
}

variable "create_oidc_provider" {
  description = "true면 GitHub OIDC provider 자원을 생성. 한 AWS 계정에 1개만 — env 중 1곳만 true."
  type        = bool
  default     = false
}

variable "existing_oidc_provider_arn" {
  description = "create_oidc_provider=false일 때 사용할 기존 OIDC provider ARN."
  type        = string
  default     = ""
}

variable "github_actions_sub_patterns" {
  description = <<-EOT
    GitHub Actions OIDC sub claim 매칭 패턴.
      예) dev : ["repo:byungju0/261RCOSE45700:ref:refs/heads/main"]
          prod: ["repo:byungju0/261RCOSE45700:environment:prod"]
  EOT
  type        = list(string)
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
