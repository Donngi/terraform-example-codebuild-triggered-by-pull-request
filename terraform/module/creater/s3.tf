# ------------------------------------------------------------
# S3 bucket 
# ------------------------------------------------------------

resource "aws_s3_bucket" "buildspec" {
  bucket = "ci-pull-request-buildspec-bucket-${data.aws_caller_identity.current.account_id}"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "buildspec" {
  bucket = aws_s3_bucket.buildspec.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------
# buildspec.yml
# ------------------------------------------------------------

resource "aws_s3_bucket_object" "buildspec" {
  bucket = aws_s3_bucket.buildspec.id
  key    = "buildspec.yml"
  source = "${path.module}/buildspec.yml"

  etag = filemd5("${path.module}/buildspec.yml")
}
