###############################################################################
# CloudFront Origin Access Control (OAC)
###############################################################################

resource "aws_cloudfront_origin_access_control" "this" {
  count = var.s3_origin_bucket != null ? 1 : 0

  name                              = "${var.name}-oac"
  description                       = "OAC for ${var.name} S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

###############################################################################
# CloudFront Cache Policy
###############################################################################

resource "aws_cloudfront_cache_policy" "this" {
  name        = "${var.name}-cache-policy"
  comment     = "Cache policy for ${var.name}"
  default_ttl = var.default_ttl
  min_ttl     = var.min_ttl
  max_ttl     = var.max_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

###############################################################################
# CloudFront Response Headers Policy
###############################################################################

resource "aws_cloudfront_response_headers_policy" "this" {
  count = var.response_headers_policy != null ? 1 : 0

  name    = "${var.name}-response-headers"
  comment = "Response headers policy for ${var.name}"

  dynamic "security_headers_config" {
    for_each = var.response_headers_policy.security_headers_config != null ? [var.response_headers_policy.security_headers_config] : []
    content {
      dynamic "strict_transport_security" {
        for_each = security_headers_config.value.strict_transport_security != null ? [security_headers_config.value.strict_transport_security] : []
        content {
          access_control_max_age_sec = strict_transport_security.value.max_age
          include_subdomains         = strict_transport_security.value.include_subdomains
          preload                    = strict_transport_security.value.preload
          override                   = true
        }
      }

      content_type_options {
        override = security_headers_config.value.content_type_options
      }

      frame_options {
        frame_option = security_headers_config.value.frame_options
        override     = true
      }

      xss_protection {
        mode_block = security_headers_config.value.xss_protection
        protection = security_headers_config.value.xss_protection
        override   = true
      }
    }
  }

  dynamic "cors_config" {
    for_each = var.response_headers_policy.cors_config != null ? [var.response_headers_policy.cors_config] : []
    content {
      access_control_allow_origins {
        items = cors_config.value.allowed_origins
      }
      access_control_allow_methods {
        items = cors_config.value.allowed_methods
      }
      access_control_allow_headers {
        items = cors_config.value.allowed_headers
      }
      access_control_max_age_sec       = cors_config.value.max_age
      origin_override                  = true
      access_control_allow_credentials = false
    }
  }
}

###############################################################################
# CloudFront Function
###############################################################################

resource "aws_cloudfront_function" "this" {
  count = var.cloudfront_function_code != null ? 1 : 0

  name    = "${var.name}-viewer-request"
  runtime = "cloudfront-js-2.0"
  comment = "Viewer request handler for ${var.name}"
  publish = true
  code    = var.cloudfront_function_code
}

###############################################################################
# CloudFront Distribution
###############################################################################

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN distribution for ${var.name}"
  default_root_object = var.default_root_object
  price_class         = var.price_class
  aliases             = var.domain_names
  web_acl_id          = var.waf_web_acl_id

  dynamic "origin" {
    for_each = var.s3_origin_bucket != null ? [var.s3_origin_bucket] : []
    content {
      domain_name              = origin.value.bucket_regional_domain_name
      origin_id                = "S3-${origin.value.bucket_id}"
      origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
    }
  }

  dynamic "origin" {
    for_each = var.alb_origin != null ? [var.alb_origin] : []
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id

      custom_origin_config {
        http_port              = origin.value.http_port
        https_port             = origin.value.https_port
        origin_protocol_policy = origin.value.protocol
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = var.s3_origin_bucket != null ? "S3-${var.s3_origin_bucket.bucket_id}" : var.alb_origin.origin_id
    cache_policy_id            = aws_cloudfront_cache_policy.this.id
    response_headers_policy_id = length(aws_cloudfront_response_headers_policy.this) > 0 ? aws_cloudfront_response_headers_policy.this[0].id : null
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true

    dynamic "function_association" {
      for_each = var.cloudfront_function_code != null ? [1] : []
      content {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.this[0].arn
      }
    }

    dynamic "lambda_function_association" {
      for_each = var.lambda_edge_functions
      content {
        event_type   = lambda_function_association.value.event_type
        lambda_arn   = lambda_function_association.value.lambda_arn
        include_body = lambda_function_association.value.include_body
      }
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == null
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = var.acm_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != null ? "TLSv1.2_2021" : null
  }

  dynamic "logging_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      include_cookies = false
      bucket          = var.logging_bucket
      prefix          = var.logging_prefix
    }
  }

  tags = var.tags
}

###############################################################################
# Route 53 DNS Records
###############################################################################

resource "aws_route53_record" "this" {
  for_each = var.route53_zone_id != null ? toset(var.domain_names) : toset([])

  zone_id = var.route53_zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
