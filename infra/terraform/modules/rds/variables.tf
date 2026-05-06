variable "identifier" {
  description = "RDS instance identifier (e.g., tracker-dev)."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.13"
}

variable "major_engine_version" {
  description = "Parameter group major version (e.g., 16)."
  type        = string
  default     = "16"
}

variable "parameter_group_family" {
  description = "Parameter group family (e.g., postgres16)."
  type        = string
  default     = "postgres16"
}

variable "instance_class" {
  description = <<-EOT
    DB instance class.
    학생 계정 PIVOT: db.t4g.micro(arm64) 미가용 → db.t3.micro(x86_64) 강제.
  EOT
  type        = string
  default     = "db.t3.micro"

  validation {
    condition = contains(
      ["db.t3.micro", "db.t3.small", "db.t3.medium"],
      var.instance_class,
    )
    error_message = "학생 계정 제약: instance_class는 db.t3.micro|db.t3.small|db.t3.medium 중 하나(arm64 t4g 미가용)."
  }
}

variable "allocated_storage" {
  description = "Allocated storage in GB (gp3)."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Storage autoscaling upper bound (GB)."
  type        = number
  default     = 50
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "tracker"
}

variable "username" {
  description = "RDS master username."
  type        = string
  default     = "tracker_admin"
}

variable "backup_retention_period" {
  description = "Automated backup retention days."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Deletion protection."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy."
  type        = bool
  default     = true
}

variable "db_subnet_group_name" {
  description = <<-EOT
    Default VPC subnet group 이름.
    학생 계정에서 RDS 콘솔이 'default'를 표시하므로 보통 "default" 입력.
  EOT
  type        = string
  default     = "default"
}

variable "security_group_id" {
  description = "RDS security group ID (5432 inbound from EC2 SGs only)."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
