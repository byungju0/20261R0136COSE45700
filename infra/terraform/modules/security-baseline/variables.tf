# 학생 계정 PIVOT — 자원 미생성으로 변수 거의 미사용. 인터페이스 안정성용.

variable "env" {
  description = "Environment name (dev | prod)."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
