terraform {
  required_version = ">= 1.14, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# 학생 계정 PIVOT — 본 모듈의 모든 자원이 학생 계정 SCP에 의해
# 차단될 가능성으로 코드 비활성. 모듈 placeholder만 유지하여 environments
# 코드의 module 호출 인터페이스 안정성 보존.
#
# 제거 항목:
#   - aws_ebs_encryption_by_default      → region default 정책에 의존
#   - aws_ebs_default_kms_key             → 별도 CMK 생성 시도 안 함
#   - aws_kms_key.trail                   → KMS CMK 생성 권한 부족 가정
#   - aws_kms_alias.trail                 → 동일
#   - aws_s3_bucket.trail                 → CloudTrail destination 미생성
#   - aws_s3_bucket_*.trail               → 동일
#   - aws_cloudtrail.this                 → CloudTrail 생성 권한 부족 가정
#   - aws_budgets_budget.monthly          → 학교가 사전 설정한 Budget에 의존
#
# Production 복구 (졸업 후 실 계정 확보 시):
#   git history에서 PIVOT 이전 버전 복원 → variables.tf의 enable_* 토글 추가하여
#   환경별 분기 가능하게 확장.
