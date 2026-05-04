# 학생 계정 PIVOT — Default VPC 사용으로 거의 모든 변수 제거.
# region/tags만 남김.

variable "region" {
  description = "AWS region (data source는 provider region을 사용하지만 outputs용으로 보존)."
  type        = string
}

variable "tags" {
  description = "Common tags (현재 본 모듈은 신규 자원을 만들지 않아 미사용. 일관성 보존)."
  type        = map(string)
  default     = {}
}
