# 학생 계정 PIVOT — 본 모듈은 자원 미생성(placeholder)이며 environments 어디에서도
# 호출되지 않는다. 변수 정의도 모두 제거 (이전 env / tags는 unused 잡힘).
#
# 졸업 후 production 환경에서 CloudTrail / KMS CMK / EBS encryption / Budgets
# 자원을 복원할 때 다음 변수 정의도 git history에서 함께 복원:
#   variable "env"  { type = string }
#   variable "tags" { type = map(string) default = {} }
