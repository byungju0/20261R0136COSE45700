output "bucket_name" {
  description = "Archive bucket name."
  value       = aws_s3_bucket.archive.id
}

output "bucket_arn" {
  description = "Archive bucket ARN."
  value       = aws_s3_bucket.archive.arn
}
