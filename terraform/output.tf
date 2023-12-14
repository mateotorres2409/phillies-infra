output "dns_lb" {
  value       = aws_lb.project-lb.dns_name
}

output "bucket_regional_domain_name" {
  value = data.aws_s3_bucket.bucket_project.bucket_regional_domain_name
}

output "bucket_id" {
  value = data.aws_s3_bucket.bucket_project.id
}

output "bucket_arn" {
  value = data.aws_s3_bucket.bucket_project.arn
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.my_distrib.domain_name
}

output "cloudfront_arn" {
  value = aws_cloudfront_distribution.my_distrib.arn
}