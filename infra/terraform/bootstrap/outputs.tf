output "tfstate_bucket_name" {
  description = "S3 bucket name for terraform state backend."
  value       = aws_s3_bucket.tfstate.id
}

output "tfstate_bucket_arn" {
  description = "S3 bucket ARN for terraform state backend."
  value       = aws_s3_bucket.tfstate.arn
}

output "region" {
  description = "AWS region the bootstrap was applied to."
  value       = var.region
}
