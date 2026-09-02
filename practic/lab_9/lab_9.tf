provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}


resource "aws_s3_bucket" "critical_archive" {

  bucket = "terraform-associate-lab9-archive-${data.aws_caller_identity.current.account_id}"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "service_logs" {
  bucket = "terraform-associate-lab9-logs-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    ignore_changes = [tags["OperationsNote"]]
  }

  tags = {
    Name           = "terraform-associate-lab9-logs-${data.aws_caller_identity.current.account_id}"
    Environment    = "Prd"
    OperationsNote = "Notes"
    ManagedBy      = "Terraform"
  }

  depends_on = [aws_s3_bucket.critical_archive]
}

output "critical_archive_bucket_name" {
  description = "Name of the critical archive S3 bucket"
  value       = aws_s3_bucket.critical_archive.bucket
}

output "service_logs_bucket_name" {
  description = "Name of the application logs S3 bucket"
  value       = aws_s3_bucket.service_logs.bucket
}

# Part 5
moved {
  from = aws_s3_bucket.application_logs
  to   = aws_s3_bucket.service_logs
}
