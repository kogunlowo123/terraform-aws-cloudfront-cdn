output "distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_hosted_zone_id" {
  description = "The hosted zone ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "distribution_status" {
  description = "The current status of the distribution"
  value       = aws_cloudfront_distribution.this.status
}

output "oac_id" {
  description = "The ID of the Origin Access Control"
  value       = length(aws_cloudfront_origin_access_control.this) > 0 ? aws_cloudfront_origin_access_control.this[0].id : null
}

output "cache_policy_id" {
  description = "The ID of the cache policy"
  value       = aws_cloudfront_cache_policy.this.id
}

output "cloudfront_function_arn" {
  description = "The ARN of the CloudFront function"
  value       = length(aws_cloudfront_function.this) > 0 ? aws_cloudfront_function.this[0].arn : null
}

output "route53_records" {
  description = "Map of Route 53 records created"
  value       = { for k, v in aws_route53_record.this : k => v.fqdn }
}
