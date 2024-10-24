resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  website {
    redirect_all_requests_to = var.host_name
  }

  versioning {
    enabled = true
  }

  object_ownership {
    rule = "BucketOwnerEnforced"
  }

  tags = var.tags
}

# Bucket policy to allow public read-only access
resource "aws_s3_bucket_policy" "public_access" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "s3:GetObject"
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.this.arn}/*"
        Principal = "*"
      },
    ]
  })
}
