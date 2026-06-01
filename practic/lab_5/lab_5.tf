provider "aws" {
  region = "us-east-1"
}


variable "network_environments" {
  type = map(object({
    cidr = string
  }))

  default = {
    "STAGE-environment" = { cidr = "10.1.0.0/16" }
    "PROD_Cluster-North " = { cidr = "10.2.0.0/16" }
  }
}


locals {
  clean_environment = {for k, v in var.network_environments: replace(trimspace(lower(k)),"-","_" ) => v}


}


output "env" {
  value = local.clean_environment
}


resource "aws_vpc" "main" {
  
  for_each = local.clean_environment
  cidr_block       = each.value.cidr
  instance_tenancy = "default"

tags = {
    Name = "vpc-${each.key}"
  }
}

