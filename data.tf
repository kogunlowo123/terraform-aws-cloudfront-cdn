data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_cloudfront_cache_policy" "managed_caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "managed_cors_s3" {
  name = "Managed-CORS-S3Origin"
}
