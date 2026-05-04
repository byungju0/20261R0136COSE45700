variable "bucket_name_prefix" {
  description = "S3 bucket name prefix (e.g., tracker-archive)."
  type        = string
  default     = "tracker-archive"
}

variable "env" {
  description = "Environment name (dev | prod)."
  type        = string
}

variable "crawler_role_arn" {
  description = "Crawler EC2 IAM Role ARN — only Principal allowed to PutObject."
  type        = string
}

variable "access_log_bucket_id" {
  description = "Access log target bucket ID (Task 8 cloudtrail bucket). 비워두면 logging 비활성."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
