terraform {
  required_version = ">= 1.14, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# 학생 계정 PIVOT — Custom VPC 생성 X.
# RDS 콘솔에서 Default VPC만 선택 가능하다는 SCP 제약 확인. 일관성을 위해
# EC2도 같은 Default VPC에 배치한다.
#
# 본 모듈은 Default VPC + 그 안의 모든 subnet을 data source로 lookup만 수행.
# Subnet selection은 환경별로 ID 직접 지정 가능 (variable로).

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Default VPC의 subnet들은 모두 public (auto-assign public IP). 학생 계정 제약상
# private subnet 신규 생성 시도 X.
data "aws_subnet" "selected" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

locals {
  # 가용 subnet 정렬 (AZ 순)
  subnet_ids_sorted = sort([for s in data.aws_subnet.selected : s.id])
}
