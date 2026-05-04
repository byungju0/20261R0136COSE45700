terraform {
  required_version = ">= 1.14, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# 모든 SG는 외부 22번 inbound 미정의 (SSH 키 미사용 — SSM Session Manager 단독).
# Checkov CKV_AWS_24/CKV_AWS_25 (22/3389 inbound 0.0.0.0/0 차단) 자동 통과.

##
# Crawler SG — outbound 443 + 80 only (S3 endpoint + 외부 사이트). inbound none.
##
module "crawler" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name        = "${var.name_prefix}-crawler"
  description = "Crawler EC2 — outbound 443/80 only, no inbound"
  vpc_id      = var.vpc_id

  # inbound 0건 (SSM은 outbound only로 동작)
  ingress_with_cidr_blocks = []

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS to S3 endpoint and external sites"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP to external sites"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = merge(var.tags, { Service = "crawler" })
}

##
# Detection SG — outbound 443 (VARCO API) + 5432 (RDS, source SG). inbound none.
##
module "detection" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name        = "${var.name_prefix}-detection"
  description = "Detection EC2 — outbound 443 (VARCO) + 5432 (RDS), no inbound"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = []

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS to VARCO API and AWS endpoints"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = merge(var.tags, { Service = "detection" })
}

##
# API SG — inbound 80/443 (퍼블릭), inbound 6379 self-ref (Redis docker-compose 동거).
# inbound 22 미정의.
##
module "api" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name        = "${var.name_prefix}-api"
  description = "API EC2 — public 80/443 inbound, self-ref 6379 for Redis"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP from public"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS from public"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  # Redis 6379 — 자기 SG 내부에서만 (docker-compose 동거 가정)
  ingress_with_self = [
    {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      description = "Redis 6379 self-reference (docker-compose colocated)"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Egress all (HTTPS to AWS endpoints, RDS, etc.)"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = merge(var.tags, { Service = "api" })
}

##
# RDS SG — inbound 5432 only from {detection, api}. egress none.
##
module "rds" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name        = "${var.name_prefix}-rds"
  description = "RDS PostgreSQL — inbound 5432 from detection + api SGs only"
  vpc_id      = var.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "PostgreSQL from detection EC2 SG"
      source_security_group_id = module.detection.security_group_id
    },
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "PostgreSQL from api EC2 SG"
      source_security_group_id = module.api.security_group_id
    },
  ]
  number_of_computed_ingress_with_source_security_group_id = 2

  # egress 없음 — RDS는 인바운드만 받는다
  egress_with_cidr_blocks = []

  tags = merge(var.tags, { Service = "rds" })
}

##
# Detection → RDS egress 허용 (RDS SG와 양방향 매칭)
##
resource "aws_vpc_security_group_egress_rule" "detection_to_rds" {
  security_group_id            = module.detection.security_group_id
  referenced_security_group_id = module.rds.security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL to RDS SG"
}

##
# API → RDS egress (이미 API egress all 이지만 명시적으로 추가하지 않음 — all egress가 포함)
##
