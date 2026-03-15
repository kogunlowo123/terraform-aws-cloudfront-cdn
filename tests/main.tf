terraform {
  required_version = ">= 1.7.0"
}

module "test" {
  source = "../"

  project_name = "test-cdn"
  environment  = "test"

  s3_origin_bucket = {
    bucket_regional_domain_name = "test-bucket.s3.us-east-1.amazonaws.com"
    bucket_id                   = "test-bucket"
  }

  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  min_ttl     = 0
  default_ttl = 3600
  max_ttl     = 86400

  custom_error_responses = [
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

  geo_restriction_type      = "none"
  geo_restriction_locations = []
  enable_logging            = false

  tags = {
    Test = "true"
  }
}
