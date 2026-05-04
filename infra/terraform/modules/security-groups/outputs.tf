output "crawler_sg_id" {
  description = "Crawler EC2 security group ID."
  value       = module.crawler.security_group_id
}

output "detection_sg_id" {
  description = "Detection EC2 security group ID."
  value       = module.detection.security_group_id
}

output "api_sg_id" {
  description = "API EC2 security group ID."
  value       = module.api.security_group_id
}

output "rds_sg_id" {
  description = "RDS security group ID."
  value       = module.rds.security_group_id
}
