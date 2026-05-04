# Module: security-groups

서비스별 격리된 보안 그룹 4종.

| SG | inbound | egress |
|---|---|---|
| **crawler** | 없음 | 443/80 → 0.0.0.0/0 |
| **detection** | 없음 | 443 → 0.0.0.0/0, 5432 → rds-sg |
| **api** | 80/443 → 0.0.0.0/0, 6379 self-ref | all (HTTPS to AWS, RDS 등) |
| **rds** | 5432 ← {detection-sg, api-sg} | 없음 |

## 보안 baseline

- 모든 SG inbound 22 미정의 → Checkov `CKV_AWS_24` 통과
- 모든 SG inbound 3389 미정의 → Checkov `CKV_AWS_25` 통과
- RDS는 source SG 참조로만 접근 가능 → 인터넷에서 라우팅 자체 불가 (NFR7)
- Redis 6379는 API SG 자기 참조만 → 외부 차단 (NFR7)

## SSM Session Manager

EC2 접근은 SSM 단독. SSM은 **outbound HTTPS(443)** 로 동작하므로 모든 EC2 SG의 egress 443은 필수.

## 사용 예

```hcl
module "security_groups" {
  source = "../../modules/security-groups"

  name_prefix = "tracker-dev"
  vpc_id      = module.networking.vpc_id

  tags = local.common_tags
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
