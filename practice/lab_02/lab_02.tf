provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {
  
}

variable "s3_lab2" {
    type = string
    default = "lab2"
}


resource "aws_s3_bucket" "lab2_bucket" {
    count = 3
    bucket = format("%s-%s-%d",var.s3_lab2,data.aws_caller_identity.current.account_id,count.index)
    bucket_namespace = "account-regional"

tags = {
    Identifier = "Bucket number ${count.index}"
  }
}