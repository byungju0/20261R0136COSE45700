terraform {
  required_version = ">= 1.14, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# 학생 계정 PIVOT —
#   - Default VPC 강제 → custom subnet group 미생성, RDS 모듈 default subnet group 사용
#   - publicly_accessible = true 강제 (학생 계정 SCP)
#   - 보안 보강: SG inbound 5432 source = EC2 SG IDs only + parameter group rds.force_ssl=1
#   - db.t3.micro 강제 (db.t4g.micro arm64 미가용)
#   - 샌드박스 템플릿 → Single-AZ만 가능

resource "random_password" "admin" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?"
}

resource "aws_secretsmanager_secret_version" "admin_password" {
  secret_id     = var.admin_password_secret_id
  secret_string = random_password.admin.result

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Parameter group — TLS만 허용 (publicly_accessible=true 보안 보강)
resource "aws_db_parameter_group" "force_ssl" {
  name        = "${var.identifier}-force-ssl"
  family      = var.parameter_group_family
  description = "Force TLS on PostgreSQL connections (rds.force_ssl=1) — student account publicly_accessible=true 보안 보강"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = merge(var.tags, { Module = "rds" })

  lifecycle {
    create_before_destroy = true
  }
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.2"

  identifier = var.identifier

  engine               = "postgres"
  engine_version       = var.engine_version
  family               = var.parameter_group_family
  major_engine_version = var.major_engine_version
  instance_class       = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.username
  password = random_password.admin.result

  manage_master_user_password = false

  # 학생 계정 강제: publicly_accessible = true
  publicly_accessible    = true
  multi_az               = false # 샌드박스 템플릿 강제 + 학생 예산
  vpc_security_group_ids = [var.security_group_id]
  port                   = 5432

  # Default VPC subnet group 사용 — 신규 subnet group 생성 X (학생 계정 + Default VPC 일관성)
  create_db_subnet_group = false
  db_subnet_group_name   = var.db_subnet_group_name # 보통 "default"

  # Custom parameter group 적용 — force_ssl=1
  parameter_group_name      = aws_db_parameter_group.force_ssl.name
  create_db_parameter_group = false
  use_identifier_prefix     = false

  backup_retention_period  = var.backup_retention_period
  backup_window            = "17:00-18:00" # KST 02:00-03:00
  maintenance_window       = "Sun:18:00-Sun:19:00"
  delete_automated_backups = !var.deletion_protection

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = "${var.identifier}-final-snapshot"

  auto_minor_version_upgrade = true

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = false

  tags = merge(var.tags, { Module = "rds" })
}
