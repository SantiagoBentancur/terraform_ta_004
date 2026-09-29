
provider "aws" {
  region = "us-east-1"
}


variable "project_module" {
  type = list(string)
  default = ["analytics", "billing", "security"]
}

resource "aws_sns_topic" "user_updates" {
  count = length(var.project_module)
  name = "user-updates-topic-${var.project_module[count.index]}"
}


resource "aws_sns_topic" "user_updates_for_each" {
  for_each = toset(var.project_module)
  name = "user-updates-topic-${each.value}"
}
