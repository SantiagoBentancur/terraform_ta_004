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
  env     = "PRD"
  project = "checkpoint-2"
}
