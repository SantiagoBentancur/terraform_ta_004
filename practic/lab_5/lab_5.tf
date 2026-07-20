provider "aws" {
  region = "us-east-1"
}

variable "network_environments" {
  description = "VPC configurations with deliberately inconsistent input keys"
  type = map(object({
    cidr = string
  }))

  default = {
    "STAGE-environment " = {
      cidr = "10.1.0.0/16"
    }
    "PROD_Cluster-North " = {
      cidr = "10.2.0.0/16"
    }
  }
}

locals {
  clean_environments = {
    for key, value in var.network_environments :
    replace(trimspace(lower(key)), "-", "_") => value
  }
}

resource "aws_vpc" "environment" {
  for_each = local.clean_environments

  cidr_block       = each.value.cidr
  instance_tenancy = "default"

  tags = {
    Name        = "vpc-${each.key}"
    Environment = each.key
    ManagedBy   = "Terraform"
  }
}

output "normalized_environments" {
  description = "Environment map after key normalization"
  value       = local.clean_environments
}
