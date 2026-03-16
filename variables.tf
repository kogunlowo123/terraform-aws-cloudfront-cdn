variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "domain_names" {
  description = "List of domain names (CNAMEs) for the CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
  default     = null
}

variable "s3_origin_bucket" {
  description = "S3 bucket configuration for the primary origin"
  type = object({
    bucket_regional_domain_name = string
    bucket_id                   = string
  })
  default = null
}

variable "alb_origin" {
  description = "ALB origin configuration"
  type = object({
    domain_name = string
    origin_id   = string
    http_port   = optional(number, 80)
    https_port  = optional(number, 443)
    protocol    = optional(string, "https-only")
  })
  default = null
}

variable "default_root_object" {
  description = "Default root object for the distribution"
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "min_ttl" {
  description = "Minimum TTL for cached objects in seconds"
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default TTL for cached objects in seconds"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Maximum TTL for cached objects in seconds"
  type        = number
  default     = 86400
}

variable "custom_error_responses" {
  description = "List of custom error response configurations"
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number, 300)
  }))
  default = [
    {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    },
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    }
  ]
}

variable "waf_web_acl_id" {
  description = "WAF Web ACL ID to associate with the distribution"
  type        = string
  default     = null
}

variable "lambda_edge_functions" {
  description = "Lambda@Edge function associations for the default cache behavior"
  type = list(object({
    event_type   = string
    lambda_arn   = string
    include_body = optional(bool, false)
  }))
  default = []
}

variable "cloudfront_function_code" {
  description = "CloudFront function code for viewer request handling"
  type        = string
  default     = null
}

variable "geo_restriction_type" {
  description = "Geo restriction type: none, whitelist, or blacklist"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for DNS records"
  type        = string
  default     = null
}

variable "enable_logging" {
  description = "Enable access logging for the distribution"
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "S3 bucket domain name for access logs"
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Prefix for log file names"
  type        = string
  default     = "cloudfront/"
}

variable "response_headers_policy" {
  description = "Custom response headers policy configuration"
  type = object({
    security_headers_config = optional(object({
      strict_transport_security = optional(object({
        max_age            = number
        include_subdomains = optional(bool, true)
        preload            = optional(bool, true)
      }))
      content_type_options = optional(bool, true)
      frame_options        = optional(string, "DENY")
      xss_protection       = optional(bool, true)
    }))
    cors_config = optional(object({
      allowed_origins = list(string)
      allowed_methods = optional(list(string), ["GET", "HEAD"])
      allowed_headers = optional(list(string), ["*"])
      max_age         = optional(number, 86400)
    }))
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
