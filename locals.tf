locals {
  name_prefix = "${var.project_name}-${var.environment}"

  s3_origin_id  = var.s3_origin_bucket != null ? "S3-${var.s3_origin_bucket.bucket_id}" : null
  alb_origin_id = var.alb_origin != null ? var.alb_origin.origin_id : null

  default_origin_id = local.s3_origin_id != null ? local.s3_origin_id : local.alb_origin_id

  use_oac = var.s3_origin_bucket != null

  use_cloudfront_function = var.cloudfront_function_code != null

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "terraform-aws-cloudfront-cdn"
  })
}
