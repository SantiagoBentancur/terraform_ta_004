terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "bucket_name" {
  type = string
}

# resource "aws_s3_bucket" "archive" {
#   bucket = var.bucket_name

#   tags = {
#     ManagedBy = "Terraform"
#     Purpose   = "Lab_13"
#   }
# }

# output "bucket_name" {
#   description = "Name of the managed S3 bucket"
#   value       = aws_s3_bucket.archive.bucket
# }

moved {
  from = aws_s3_bucket.imported
  to   = aws_s3_bucket.archive
}

removed {
  from = aws_s3_bucket.archive

  lifecycle {
    destroy = false
  }
}
