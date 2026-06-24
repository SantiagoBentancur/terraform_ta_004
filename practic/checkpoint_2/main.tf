terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.47.0"
    }
  }
  required_version = ">= 1.14.7"
}


provider "aws" {
  region = "us-east-1"
}


module "network" {
  source  = "./modules/network"
  env     = "DEV"
  project = "checkpoint-2"
  single_nat_gateway = true
  
}
