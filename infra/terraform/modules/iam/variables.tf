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

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
