terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}


provider "aws" {
  alias  = "west"
  region = "us-west-2"
}


module "regional_inventory" {
  source = "./modules/regional_inventory"

  providers = {
    aws.primary   = aws
    aws.secondary = aws.west
  }
}

output "regional_inventory" {
  value = module.regional_inventory.availability_zones
}
