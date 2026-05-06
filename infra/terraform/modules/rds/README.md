# Module: rds (학생 계정 PIVOT 사양)

PostgreSQL 16.13 db.t3.micro Single-AZ + automated backup 7일 + **publicly_accessible=true(학생 계정 강제)** + `rds.force_ssl=1` 보안 보강.

## 학생 계정 제약 반영

| 항목 | 본 모듈 | 사유 |
|---|---|---|
| Engine | PostgreSQL 16.13 | RDS 16.x 최신 minor + 학생 계정 허용 엔진 |
| Class | db.t3.micro (x86_64) | db.t4g.micro(arm64) 미가용 |
| `multi_az` | false | 샌드박스 템플릿 강제 |
| `publicly_accessible` | **true** | 학생 계정 SCP 강제 (위반 시 콘솔 차단) |
| Subnet group | **default** (Default VPC) | Custom VPC 미생성 → Default VPC subnet group 사용 |
| Parameter group | **`{identifier}-force-ssl`** with `rds.force_ssl=1` | TLS만 허용 → 평문 접속 차단 |
| storage_encrypted | true | 학생 계정에서도 가능 (region default key) |
| auto_minor_version_upgrade | true | PG 16 minor patch 자동 |

## publicly_accessible=true 보안 보강 패턴

학생 계정 SCP가 강제하는 publicly_accessible=true는 RDS 엔드포인트가 인터넷에서 라우팅 가능하다는 의미. 그러나 실제 접근은 다음 가드로 차단:

1. **Security Group inbound 5432 source = {detection-sg, api-sg} ID only** — 인터넷에서 5432 시도 시 SG가 차단 (router 도달 → SG drop)
2. **Parameter group `rds.force_ssl=1`** — 평문 접속 거절, TLS만 허용
3. **`random_password` 32자 special** — 무차별 대입 비현실적
4. **Secrets Manager 보관 + EC2 IAM Role만 GetSecretValue** — DB credentials 외부 노출 X

→ 실효 보안은 publicly_accessible=false와 SG 차단의 조합과 동등 수준. NFR7 "엄격 해석" 위반은 맞지만 학생 계정 제약상 어쩔 수 없음.

## 비밀번호 관리 — RDS-managed (보안 fix 2026-05-06)

`manage_master_user_password = true` 옵션으로 **RDS가 자동으로 Secrets Manager secret 생성 + 비밀번호 관리**. AWS-managed `alias/aws/secretsmanager` KMS 자동 사용. ARN은 `module.rds.master_user_secret_arn`으로 노출.

**이전 패턴(`random_password` + `aws_secretsmanager_secret_version`)은 보안 review fix로 제거됨**:
- 그 패턴은 비밀번호를 tfstate에 평문으로 저장하는 위험이 있었음
- `random_password.admin.result`와 `secret_version.secret_string` 모두 state 평문 저장
- tfstate S3 버킷이 SSE-S3(KMS CMK X)이라 `s3:GetObject` 권한자가 비밀번호 획득 가능
- RDS가 `publicly_accessible=true`(학생 계정 강제)라 비밀번호 + endpoint 조합으로 직접 master 접속 가능

→ **RDS-managed 전환으로 tfstate 평문 비밀번호 노출 0.** Detection/API EC2는 `module.rds.master_user_secret_arn`에 IAM `GetSecretValue` 권한으로 비밀번호 조회.

> **3중 방어 매트릭스 갱신:**
> 1. SG inbound 5432 source = EC2 SG IDs only (인터넷 SG drop)
> 2. Parameter group `rds.force_ssl=1` (TLS만 허용)
> 3. **RDS-managed master password (tfstate 평문 노출 X) + Secrets Manager (AWS-managed KMS) + EC2 IAM Role만 ARN 한정 GetSecretValue**

## 사용 예

```hcl
module "rds" {
  source = "../../modules/rds"

  identifier             = "tracker-dev"
  engine_version         = "16.13"
  instance_class         = "db.t3.micro"
  db_subnet_group_name   = "default"  # Default VPC
  security_group_id      = module.security_groups.rds_sg_id
  # admin_password_secret_id 인자 제거됨 — RDS-managed 자동 생성

  deletion_protection = false
  skip_final_snapshot = true

  tags = local.common_tags
}

# environments에서 IAM Role에 RDS-managed secret ARN 주입
module "iam" {
  source = "../../modules/iam"
  # ...
  detection_secret_arns = [
    module.secrets.varco_api_key_secret_arn,
    module.rds.master_user_secret_arn,
  ]
  api_secret_arns = [module.rds.master_user_secret_arn]
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
