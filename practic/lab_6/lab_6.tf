
provider "aws" {
  region = "us-east-1"
}

variable "project_modules" {
  type    = list(string)
  default = ["analytics", "billing", "security"]
}

resource "aws_sns_topic" "count_topics" {
  count = length(var.project_modules)
  name  = "count-topic-${var.project_modules[count.index]}"
}

resource "aws_sns_topic" "foreach_topics" {
  for_each = toset(var.project_modules)
  name     = "foreach-topic-${each.key}"
}
