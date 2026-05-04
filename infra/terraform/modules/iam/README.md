# Module: iam

EC2 Instance Roles 3종 + GitHub OIDC + GitHub Actions Terraform Role.

## EC2 Instance Roles

| Role | 첨부 정책 | 용도 |
|---|---|---|
| `{prefix}-ec2-crawler` | SSM + S3 PutObject (특정 버킷 ARN) | 크롤링 결과 S3 업로드 |
| `{prefix}-ec2-detection` | SSM + Secrets `GetSecretValue` (varco_api_key 등) | VARCO API 호출 |
| `{prefix}-ec2-api` | SSM + Secrets `GetSecretValue` (rds_admin_password 등) | RDS 접속 |

모든 role에 `AmazonSSMManagedInstanceCore` 첨부 → SSH 키 없이 SSM Session Manager로 접근 가능 (NFR6, NFR7).

## GitHub OIDC

- 한 AWS 계정에 OIDC provider는 1개만 생성. `create_oidc_provider = true`인 환경(보통 dev)에서 한 번만 생성.
- 다른 환경(prod 등)은 `create_oidc_provider = false` + `existing_oidc_provider_arn = "..."` 로 참조.

## GitHub Actions Role trust

`github_actions_sub_patterns`로 trust 조건을 명시한다.

```hcl
# dev
github_actions_sub_patterns = [
  "repo:byungju0/261RCOSE45700:ref:refs/heads/main",
  "repo:byungju0/261RCOSE45700:pull_request",
]

# prod (GitHub Environments 보호 규칙으로 수동 승인 게이트)
github_actions_sub_patterns = [
  "repo:byungju0/261RCOSE45700:environment:prod",
]
```

## 와일드카드 정책에 대한 메모 (deferred-work)

GitHub Actions Terraform Role의 mutate 정책은 일부 액션에서 `Resource: "*"`를 사용한다. 학생 프로젝트 범위에서 service-level write로 시작하고, 장기 운영 전환 시 ARN 단위로 좁혀야 한다 — Story 5-3 deferred-work 참조.

EC2 Instance Role은 모두 ARN 한정 → Checkov `CKV_AWS_111` 통과 (Crawler S3 정책, Detection/API Secrets 정책).

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
