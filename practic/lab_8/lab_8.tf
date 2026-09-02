provider "aws" {
  region = "us-east-1"
}

variable "team_config" {
  type = object({
    team_name  = string
    developers = list(string)
  })

  validation {
    condition     = startswith(var.team_config.team_name, "dev-")
    error_message = "team_name must start with dev-"
  }

  validation {
    condition     = length(var.team_config.developers) == length(toset(var.team_config.developers))
    error_message = "developer names must be unique"
  }

  default = {
    team_name  = "dev-backend"
    developers = ["alice", "bob", "charlie"]
  }

}

resource "aws_iam_user" "team" {
  for_each = toset(var.team_config.developers)
  name     = "${var.team_config.team_name}-${each.value}"

  lifecycle {
    precondition {
      condition     = length(var.team_config.developers) >= 2
      error_message = "The minimum team size is 2"
    }
  }

  tags = {
    Team      = var.team_config.team_name
    ManagedBy = "Terraform"
  }
}

output "developer_arns" {
  value = {
    for user in aws_iam_user.team : user.name => user.arn
  }
}
