output "endpoint" {
  description = "RDS connection endpoint (host:port)."
  value       = module.rds.db_instance_endpoint
}

output "address" {
  description = "RDS hostname."
  value       = module.rds.db_instance_address
}

output "port" {
  description = "RDS port."
  value       = module.rds.db_instance_port
}

output "db_name" {
  description = "Initial database name."
  value       = module.rds.db_instance_name
}

output "username" {
  description = "Master username."
  value       = module.rds.db_instance_username
  sensitive   = true
}

output "subnet_group_name" {
  description = "DB subnet group name."
  value       = aws_db_subnet_group.this.name
}
