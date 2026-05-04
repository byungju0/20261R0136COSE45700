variable "service_name" {
  description = "Service-qualified name (e.g., tracker-dev-crawler)."
  type        = string
}

variable "instance_type" {
  description = <<-EOT
    EC2 instance type.
    학생 계정 SCP 제약 — EC2 콘솔에서 직접 확인됨 (2026-05-04):
    t3.{nano, micro, small, medium} 4종만 launch 가능. Graviton(arm64) t4g/r6g/r8g 시리즈 미가용.
    t3.large 이상도 차단됨. 따라서 EC2 최대 사양은 t3.medium (2vCPU/4GB).
  EOT
  type        = string

  validation {
    condition = contains(
      ["t3.nano", "t3.micro", "t3.small", "t3.medium"],
      var.instance_type,
    )
    error_message = "학생 계정 제약: instance_type은 t3.{nano,micro,small,medium} 4종 중 하나여야 함."
  }
}

variable "ami_id" {
  description = "AMI ID. 비워두면 최신 Amazon Linux 2023 x86_64 자동 선택."
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "EC2 배치 subnet (Default VPC의 public subnet)."
  type        = string
}

variable "security_group_id" {
  description = "EC2에 붙일 보안 그룹 ID."
  type        = string
}

variable "iam_instance_profile" {
  description = "EC2 IAM Instance Profile name."
  type        = string
}

variable "associate_public_ip_address" {
  description = "Default VPC subnet은 default public IP 자동 할당. 명시적으로 true."
  type        = bool
  default     = true
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size (gp3, region default 암호화)."
  type        = number
  default     = 30
}

variable "user_data" {
  description = "EC2 user_data 스크립트. 기본은 공백 (애플리케이션 배포는 Story 5.2)."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
