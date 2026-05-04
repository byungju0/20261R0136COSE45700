output "vpc_id" {
  description = "Default VPC ID."
  value       = data.aws_vpc.default.id
}

output "vpc_cidr" {
  description = "Default VPC CIDR."
  value       = data.aws_vpc.default.cidr_block
}

# Default VPC의 subnet들은 모두 public이며 RDS도 같은 subnet group을 사용.
# private/public 분리 없음 — 학생 계정 제약 + RDS publicly_accessible=true 강제 일관성.
output "subnet_ids" {
  description = "Default VPC의 모든 subnet ID 목록."
  value       = local.subnet_ids_sorted
}

output "first_subnet_id" {
  description = "EC2 배치용 첫 번째 subnet."
  value       = local.subnet_ids_sorted[0]
}

output "second_subnet_id" {
  description = "EC2 배치용 두 번째 subnet (AZ 분리용)."
  value       = length(local.subnet_ids_sorted) > 1 ? local.subnet_ids_sorted[1] : local.subnet_ids_sorted[0]
}
