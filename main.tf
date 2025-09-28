provider "aws" {
  region = "us-east-1"
}

# ---------------------------
# S3 Bucket (already exists)
# ---------------------------
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "moreen-cloud-resume-challenge"

  lifecycle {
    prevent_destroy = true
  }
}

# Optional: Explicitly manage bucket policy (if you want Terraform to control it)
# Import first: terraform import aws_s3_bucket_policy.frontend_policy xxssd-bucket
resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id

  
  policy = jsonencode({
    Version: "2008-10-17",
    Statement: [
        {
            Sid: "AllowCloudFrontServicePrincipal",
            Effect: "Allow",
            Principal: {
                Service: "cloudfront.amazonaws.com"
            },
            Action: "s3:GetObject",
            Resource: "arn:aws:s3:::moreen-cloud-resume-challenge/*",
            Condition: {
              StringEquals: {
                    "AWS:SourceArn": "arn:aws:cloudfront::599704543248:distribution/EVWV54UXGP4W1"
                }
            }
        }
    ]
}
  
  )
  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------
# S3 Objects (optional hybrid mode)
# ---------------------------
# Manage new files via Terraform, while leaving existing uploads unmanaged
resource "aws_s3_object" "resume_html" {
  bucket = aws_s3_bucket.frontend_bucket.id
  key    = "index.html"
  source = "index.html"
  etag   = filemd5("index..html")
  content_type = "text/html"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_object" "new_css" {
  bucket = aws_s3_bucket.frontend_bucket.id
  key    = "style.css"
  source = "style.css"
  etag   = filemd5("style.css")
  content_type = "text/css"
  lifecycle {
    prevent_destroy = true
  }
}

# Add the profile picture
resource "aws_s3_object" "profile_pic" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "aws-cloud-resume-challenge-chart.png"            # the object key in the bucket
  source       = "aws-cloud-resume-challenge-chart.png"     # path to file in your repo
  etag         = filemd5("aws-cloud-resume-challenge-chart.png")
  content_type = "image/png"
  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------
# CloudFront (already exists)
# ---------------------------
# Import first: terraform import aws_cloudfront_distribution.frontend_cdn <distribution-id>
resource "aws_cloudfront_distribution" "frontend_cdn" {
  # After import, run "terraform plan" and copy the actual distribution config here
  # Example skeleton (your imported config will be longer):
  origin {
    domain_name = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id   = "s3-origin"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  lifecycle {
    prevent_destroy = true
  }
}
