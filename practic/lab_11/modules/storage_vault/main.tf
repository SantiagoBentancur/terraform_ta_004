terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.47.0" 
    }
  }
  required_version = ">= 1.14.7" 
}

resource "aws_s3_bucket" "this" {
  bucket_prefix = var.bucket_prefix
  # Commented out to prevent accidental deletion of the bucket during testing. Uncomment if you want to allow bucket deletion.
  # lifecycle {
  #   prevent_destroy = true
  # }
}

