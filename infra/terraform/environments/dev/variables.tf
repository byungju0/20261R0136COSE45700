# 학생 계정 PIVOT 후 정리 — CI에서 OIDC + GHA Role 미사용으로 dead 변수
# (github_repository / tfstate_bucket_name) 모두 제거.

variable "region" {
  description = <<-EOT
    AWS region. Default: ap-northeast-2(Seoul).
    학생 계정 SCP `<region-restrict-policy>`가 us-east-1만 차단. 나머지 16개 region 허용.
  EOT
  type        = string
  default     = "ap-northeast-2"

  validation {
    condition = contains(
      [
        "us-east-2", "us-west-1", "us-west-2",
        "ap-south-1", "ap-northeast-1", "ap-northeast-2", "ap-northeast-3",
        "ap-southeast-1", "ap-southeast-2",
        "ca-central-1",
        "eu-central-1", "eu-west-1", "eu-west-2", "eu-west-3", "eu-north-1",
        "sa-east-1",
      ],
      var.region,
    )
    error_message = "학생 계정 제약: region이 학교 허용 화이트리스트에 없음 (us-east-1만 차단)."
  }
}

variable "name_prefix" {
  description = "리소스 prefix."
  type        = string
  default     = "tracker-dev"
}
