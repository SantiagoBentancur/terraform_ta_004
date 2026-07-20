# provider "aws" {
#   region = "us-east-1"
# }

# variable "bucket_prefix" {
#   description = "Base prefix for the S3 bucket names"
#   type        = string
#   default     = "terraform-associate-lab2"
# }

# data "aws_caller_identity" "current" {}

# resource "aws_s3_bucket" "lab" {
#   count = 3

#   bucket = format(
#     "%s-%s-%d",
#     var.bucket_prefix,
#     data.aws_caller_identity.current.account_id,
#     count.index
#   )

#   tags = {
#     Name       = "Lab 2 bucket ${count.index}"
#     Identifier = tostring(count.index)
#     ManagedBy  = "Terraform"
#   }
# }


provider "aws" {
  region = "us-east-1"
}

variable "bucket_prefix" {
  description = "Bucket names"
  type = string
  default = "terraform-associate-lab2"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "lab" {
  count = 3
  bucket = format( "%s-%s-%d",
  var.bucket_prefix,data.aws_caller_identity.current,
  count.index)
  
  tags = {
    "Name" = "Lab 2 bucket ${count.index}"
    "Identifier" = tonumber(count.index)
    ManagedBy = "Terraform"
  }
}