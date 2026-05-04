output "instance_id" {
  description = "EC2 instance ID."
  value       = module.ec2.id
}

output "instance_arn" {
  description = "EC2 instance ARN."
  value       = module.ec2.arn
}

output "private_ip" {
  description = "EC2 private IP."
  value       = module.ec2.private_ip
}

output "public_ip" {
  description = "EC2 public IP (public subnet 배치 시)."
  value       = module.ec2.public_ip
}

output "ami_id" {
  description = "Resolved AMI ID."
  value       = local.ami_id
}
