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

## 비밀번호 관리

`random_password` → `aws_secretsmanager_secret_version`(외부에서 주입한 secret_id)에 1회 저장. 이후 Console에서 회전 시 Terraform이 되돌리지 않도록 `lifecycle.ignore_changes = [secret_string]`.

## 사용 예

```hcl
module "rds" {
  source = "../../modules/rds"

  identifier               = "tracker-dev"
  engine_version           = "16.13"
  instance_class           = "db.t3.micro"
  db_subnet_group_name     = "default"  # Default VPC
  security_group_id        = module.security_groups.rds_sg_id
  admin_password_secret_id = module.secrets.rds_admin_password_secret_id

  deletion_protection = false
  skip_final_snapshot = true

  tags = local.common_tags
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
