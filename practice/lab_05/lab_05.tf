provider "aws" {
  region = "us-east-1"
}

variable "environments" {
  type = map(object({
    cidr     = string
    priority = number
  }))

  default = {
    staging = {
      cidr     = "10.1.0.0/16"
      priority = 2
    }

    production = {
      cidr     = "10.2.0.0/16"
      priority = 1
    }

    "QA-environment " = {
      cidr     = "10.3.0.0/16"
      priority = 3
    }

  }

}

locals {
  clean_environments = {
    for key, value in var.environments : replace(lower(trimspace(key)), "-", "_") => value
  }
}

resource "aws_vpc" "environment" {
  for_each         = local.clean_environments
  cidr_block       = each.value.cidr
  instance_tenancy = "default"

  tags = {
    Name        = "vpc-${each.key}"
    Environment = each.key
    Priority    = tostring(each.value.priority)
    ManagedBy   = "Terraform"
  }
}

output "normalized_environments" {
  description = "Environment definitionsE"
  value       = local.clean_environments
}
