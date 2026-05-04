# Module: secrets

AWS Secrets Manager 시크릿 placeholder 3종.

| 시크릿 | 값 주입 방법 |
|---|---|
| `{prefix}/varco-api-key` | Console 또는 ops 스크립트로 1회 주입 |
| `{prefix}/rds-admin-password` | RDS 모듈이 `random_password` → `secret_version`으로 자동 주입 |
| `{prefix}/proxy-credentials` | Console 또는 ops 스크립트로 1회 주입 |

## 평문 시크릿 금지 (NFR5)

`aws_secretsmanager_secret_version`의 `secret_string`을 Terraform 변수로 받으면 **state에 평문 저장**된다. 본 모듈은 placeholder만 정의하고 값 주입은 외부 책임으로 분리.

→ `terraform.tfvars`에 시크릿 값 0건 (CI에서 grep 가드 권장 — Story 5.2).

## 값 주입 (1회 ops 작업)

```bash
# AWS CLI로 1회 주입
aws secretsmanager put-secret-value \
  --secret-id tracker/dev/varco-api-key \
  --secret-string "$(read -s -p 'VARCO API key: ' k && echo "$k")"
```

## IAM ARN 한정

이 모듈의 `detection_secret_arns` / `api_secret_arns` output을 IAM 모듈에 그대로 주입하면 EC2 Role의 `secretsmanager:GetSecretValue`가 ARN 단위로 한정된다 → Checkov `CKV_AWS_111` 통과.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
