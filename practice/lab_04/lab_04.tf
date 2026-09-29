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

  }

}

resource "aws_vpc" "environment" {
  count            = length(var.environments)
  cidr_block       = values(var.environments)[count.index].cidr
  instance_tenancy = "default"

  tags = {
    Name        = "vpc-${keys(var.environments)[count.index]}"
    Environment = keys(var.environments)[count.index]
    Priority    = tostring(values(var.environments)[count.index].priority)
    ManagedBy   = "Terraform"
  }

}
