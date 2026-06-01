provider "aws" {
  region = "us-east-1"
}


variable "environments" {
  type = map(object({
    cidr = string 
  }))
 
  default = {
    "staging" = {cidr = "10.1.0.0/16"}
    "production" = {cidr = "10.2.0.0/16"}
      
  }
}


resource "aws_vpc" "main" {
  
  count = length(var.environments)
  cidr_block  = values(var.environments)[count.index].cidr
  instance_tenancy = "default"
  
tags = {
    Name = "vpc-${keys(var.environments)[count.index]}"
  }
}