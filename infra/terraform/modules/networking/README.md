# Module: networking (학생 계정 PIVOT 사양)

**원래는** custom VPC + public/private subnet + S3 endpoint + Flow Logs 였으나, 학생 계정 SCP 제약으로 RDS가 Default VPC 강제 → 일관성 위해 **Default VPC를 data source로 lookup만 수행**하는 형태로 단순화.

## 무엇을 안 만드나 (학생 계정 제약)

- 신규 VPC ❌
- 신규 subnet ❌
- VPC Gateway Endpoint(S3) ❌ — Default VPC 라우트 테이블 수정 권한 불확실
- VPC Flow Logs ❌ — 학생 계정에서 Flow Logs 자원 생성 권한 불확실 (deferred-work)
- NAT (어차피 NAT 없음 결정 유지) ❌

## 무엇을 lookup하나

- `data.aws_vpc.default` — Default VPC ID/CIDR
- `data.aws_subnets.default` — Default VPC의 모든 subnet
- 정렬된 subnet ID 리스트 + 첫 번째/두 번째 subnet (EC2 배치용)

## 사용 예

```hcl
module "networking" {
  source = "../../modules/networking"
  region = var.region
  tags   = local.common_tags
}

module "ec2_crawler" {
  source            = "../../modules/ec2-service"
  subnet_id         = module.networking.first_subnet_id
  # ...
}

module "ec2_api" {
  source            = "../../modules/ec2-service"
  subnet_id         = module.networking.second_subnet_id
  # ...
}
```

## Production 환경으로 복구하기 (졸업 후 실 계정 확보 시)

`environments/prod/` 코드는 본 모듈 호출 X — 본래 design(custom VPC + 4종 subnet + endpoints + Flow Logs)을 별도 모듈 또는 직접 자원으로 정의해야 함. Story 5.3 PIVOT 이전 git history 참고.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
