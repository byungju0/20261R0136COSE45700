# Module: ec2-service (학생 계정 PIVOT 사양)

x86_64 EC2 인스턴스 1개 — crawler/detection/api 공통 패턴.

## 학생 계정 제약 반영

- **Graviton(arm64) 미가용** — AMI를 Amazon Linux 2023 x86_64로 강제
- **인스턴스 타입 4종 한정** — `t3.{nano,micro,small,medium}` validation 박힘 (EC2 콘솔에서 2026-05-04 확정). 다른 값 입력 시 plan 실패. t3.large 이상도 차단
- **메모리 다운그레이드** — Crawler 16GB(r6g.large) → 4GB(t3.medium). Playwright + FlareSolverr 동시 실행 부담은 Story 5.4 부하 측정 후 재검토 (deferred-work)

## 보안 가드 (PIVOT 후 유지)

- **IMDSv2 강제** (`http_tokens = "required"`) — Checkov `CKV_AWS_79`
- **Root EBS 암호화** (`encrypted = true`) — Checkov `CKV_AWS_8`
- **public IP 할당** — Default VPC subnet은 자동 public IP. inbound는 SG에서 0으로 차단(crawler/detection) 또는 80/443만(api)

## 사용 예 (environments/dev/main.tf)

```hcl
module "ec2_crawler" {
  source = "../../modules/ec2-service"

  service_name         = "tracker-dev-crawler"
  instance_type        = "t3.medium"  # 학생 계정 4종 한정 최대 사양
  subnet_id            = module.networking.first_subnet_id
  security_group_id    = module.security_groups.crawler_sg_id
  iam_instance_profile = module.iam.crawler_instance_profile_name
  root_volume_size_gb  = 30

  tags = local.common_tags
}
```

## user_data

기본은 공백. 애플리케이션 배포(Docker pull, compose up)는 **Story 5.2 CD**가 책임. 본 스토리는 인프라 프로비저닝까지만.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
