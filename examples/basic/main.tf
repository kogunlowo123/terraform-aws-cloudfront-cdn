provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "website" {
  bucket = "my-website-bucket-example"
}

module "cloudfront_cdn" {
  source = "../../"

  project_name = "my-website"
  environment  = "prod"

  s3_origin_bucket = {
    bucket_regional_domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    bucket_id                   = aws_s3_bucket.website.id
  }

  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  tags = {
    Team = "platform"
  }
}

output "cdn_domain" {
  value = module.cloudfront_cdn.distribution_domain_name
}
