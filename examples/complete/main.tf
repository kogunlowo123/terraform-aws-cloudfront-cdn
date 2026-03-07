provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "website" {
  bucket = "my-complete-website-bucket"
}

resource "aws_s3_bucket" "logs" {
  bucket = "my-cdn-access-logs"
}

resource "aws_acm_certificate" "this" {
  domain_name       = "cdn.example.com"
  validation_method = "DNS"
}

data "aws_route53_zone" "main" {
  name = "example.com"
}

module "cloudfront_cdn" {
  source = "../../"

  project_name = "my-complete-website"
  environment  = "prod"

  domain_names        = ["cdn.example.com", "www.example.com"]
  acm_certificate_arn = aws_acm_certificate.this.arn
  route53_zone_id     = data.aws_route53_zone.main.zone_id

  s3_origin_bucket = {
    bucket_regional_domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    bucket_id                   = aws_s3_bucket.website.id
  }

  alb_origin = {
    domain_name = "api-alb-123456.us-east-1.elb.amazonaws.com"
    origin_id   = "ALB-api"
    protocol    = "https-only"
  }

  default_root_object = "index.html"
  price_class         = "PriceClass_All"

  custom_error_responses = [
    {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    },
    {
      error_code         = 404
      response_code      = 404
      response_page_path = "/404.html"
    },
  ]

  response_headers_policy = {
    security_headers_config = {
      strict_transport_security = {
        max_age            = 31536000
        include_subdomains = true
        preload            = true
      }
      content_type_options = true
      frame_options        = "DENY"
      xss_protection       = true
    }
    cors_config = {
      allowed_origins = ["https://example.com"]
      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      allowed_headers = ["*"]
      max_age         = 86400
    }
  }

  cloudfront_function_code = <<-EOT
    function handler(event) {
      var request = event.request;
      var uri = request.uri;
      if (uri.endsWith('/')) {
        request.uri += 'index.html';
      } else if (!uri.includes('.')) {
        request.uri += '/index.html';
      }
      return request;
    }
  EOT

  enable_logging = true
  logging_bucket = aws_s3_bucket.logs.bucket_domain_name
  logging_prefix = "cdn-logs/"

  geo_restriction_type      = "whitelist"
  geo_restriction_locations = ["US", "CA", "GB", "DE"]

  tags = {
    Team        = "platform"
    CostCenter  = "engineering"
  }
}

output "cdn_domain" {
  value = module.cloudfront_cdn.distribution_domain_name
}

output "distribution_id" {
  value = module.cloudfront_cdn.distribution_id
}
