# Module: security-baseline (학생 계정 PIVOT — 비활성)

학생 계정 SCP 권한 부족 가정으로 본 모듈의 모든 자원이 비활성화됨.

## 비활성된 자원

| 원래 자원 | 학생 계정 대안 |
|---|---|
| `aws_ebs_encryption_by_default` | region default 정책에 의존 (학교가 default로 켜놨을 가능성) |
| `aws_ebs_default_kms_key` | region default `alias/aws/ebs` 자동 |
| `aws_kms_key.trail` + alias | KMS CMK 생성 권한 부족 가정 |
| `aws_s3_bucket.trail` (CloudTrail destination) | CloudTrail 미생성으로 destination 불필요 |
| `aws_cloudtrail.this` | 생성 권한 부족 가정. 학교 organization trail이 있으면 그것에 의존 |
| `aws_budgets_budget.monthly` | 학교가 사전 설정한 Budget 활용. Cost Explorer로 사후 모니터링 |

## 학교 설정 활용 권장

콘솔에서 다음 항목들이 학교 default 정책으로 이미 활성화되어 있을 가능성:
- EBS encryption by default
- 학교 organization trail
- 학교 budget alert (학생별 한도)

각각 콘솔에서 1회 확인 권장 (deferred-work 항목).

## Production 복구 (졸업 후 실 계정 확보 시)

`git log infra/terraform/modules/security-baseline/main.tf` → PIVOT 이전 commit 복원하면 CloudTrail/KMS/Budgets 전체 자원이 다시 활성화됨.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
