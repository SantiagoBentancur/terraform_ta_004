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

  lifecycle {
    prevent_destroy = true
  }
}

