provider "aws" {
  region = "us-east-1"
}

variable "bucket_prefix" {
  type        = string
  description = "Prefix that will be assigned to our buckets"
  default     = "terraform-associate-lab2"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "lab" {
  count  = 3
  bucket = format("%s-%s-%d", var.bucket_prefix, data.aws_caller_identity.current.account_id, count.index)
  tags = {
    "Name"       = "lab-2-bucket-${tostring(count.index)}"
    "Identifier" = tostring(count.index)
    "ManagedBy"  = "Terraform"
  }
}
