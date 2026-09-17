variable "environment" {
  type    = string
  default = "development"
}

variable "owner_email" {
  type    = string
  default = "platform@example.com"
}

check "owner_email_format" {
  assert {
    # A stricter expression would be "^[^@]+@[^@]+\\.[^@]+$".
    condition     = can(regex("@", var.owner_email))
    error_message = "Wrong format for the email."
  }
}

locals {
  allowed_environments = ["development", "staging", "production"]
  application_name     = lower(var.environment)
}

resource "terraform_data" "application" {
  input = {
    name        = local.application_name
    environment = var.environment
    owner       = var.owner_email
  }

  lifecycle {
    precondition {
      condition     = contains(local.allowed_environments, var.environment)
      error_message = "Environment not allowed."
    }

    postcondition {
      condition     = self.output.name == lower(self.output.name)
      error_message = "Application name must be lowercase."
    }
  }
}

output "terraform_data" {
  value = terraform_data.application
}
