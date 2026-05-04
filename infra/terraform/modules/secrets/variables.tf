variable "name_prefix" {
  description = "Secret name prefix (e.g., tracker/dev)."
  type        = string
}

variable "recovery_window_in_days" {
  description = "삭제 시 복구 가능 기간 (dev=0, prod=30 권장). 0은 즉시 영구삭제."
  type        = number
  default     = 7
}

variable "kms_key_id" {
  description = "Secrets Manager 암호화에 사용할 KMS key. 비워두면 AWS 관리형 alias/aws/secretsmanager 사용."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
