provider "aws" {
  region = "us-east-1"
}


data "aws_caller_identity" "current" {}


data "aws_region" "current" {
}

resource "aws_s3_bucket" "s3_backend" {

  bucket        = format("lab-14-data-%s-%s", data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  force_destroy = true

  tags = {
    ManagedBy = "Terraform"
    Lab       = "14"
  }
}


resource "aws_s3_bucket_versioning" "versioning_s3_backend" {
  bucket = aws_s3_bucket.s3_backend.id

  versioning_configuration {
    status = "Enabled"
  }

}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.s3_backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_s3_backend" {
  bucket = aws_s3_bucket.s3_backend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


output "backend_name" {
  value = aws_s3_bucket.s3_backend.id
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
