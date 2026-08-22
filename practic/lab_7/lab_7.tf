
provider "aws" {
  region = "us-east-1"
}

# Part 1: Build and Test a Static Policy
/*
data "aws_iam_policy_document" "application_document" {

  statement {
    sid    = "ReadApplicationObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::example-application-bucket/*",
    ]
  }

  statement {
    sid    = "DescribeInstances"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "application_policy" {
  name   = "lab-7-application-policy"
  policy = data.aws_iam_policy_document.application_document.json

  tags = {
    ManagedBy = "Terraform"
  }
}

output "policy_json" {
  value = data.aws_iam_policy_document.application_document.json

}
*/

# Part 2: Refactor and Test the Dynamic Policy
variable "policy_statements" {
  description = "IAM statements included in the application policy"
  type = map(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))

  default = {
    ReadApplicationObjects = {
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["arn:aws:s3:::example-application-bucket/*"]
    }

    DescribeInstances = {
      effect    = "Allow"
      actions   = ["ec2:DescribeInstances"]
      resources = ["*"]
    }

    ReadCloudWatchMetrics = {
      effect    = "Allow"
      actions   = ["cloudwatch:GetMetricData", "cloudwatch:ListMetrics"]
      resources = ["*"]
    }
  }


}

data "aws_iam_policy_document" "application_document" {

  dynamic "statement" {
    for_each = var.policy_statements
    iterator = policy_statement
    content {
      sid       = policy_statement.key
      effect    = policy_statement.value.effect
      actions   = policy_statement.value.actions
      resources = policy_statement.value.resources
    }
  }
}

resource "aws_iam_policy" "application_policy" {
  name   = "lab-7-application-policy"
  policy = data.aws_iam_policy_document.application_document.json

  tags = {
    ManagedBy = "Terraform"
  }
}

output "policy_json" {
  value = data.aws_iam_policy_document.application_document.json

}
