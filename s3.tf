resource "aws_s3_bucket" "my_project_bucket" {
  bucket = "${lower(local.project_name)}-zentawrus"

  tags = {
    Name        = "${local.project_name}-data-bucket"
    Environment = local.environment
    ManagedBy   = "Terraform"
    Purpose     = "General Data Storage"
  }
}

resource "aws_s3_bucket_public_access_block" "my_project_bucket_public_access_block" {
  bucket = aws_s3_bucket.my_project_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "my_project_bucket_versioning" {
  bucket = aws_s3_bucket.my_project_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.my_project_bucket.bucket
  description = "The unique name of the S3 bucket created."
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.my_project_bucket.arn
  description = "The ARN of the S3 bucket created."
}