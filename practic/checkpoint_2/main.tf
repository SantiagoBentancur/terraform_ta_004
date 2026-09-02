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
  source             = "./modules/network"
  env                = "DEV"
  project            = "checkpoint-2"
  single_nat_gateway = true

}


module "security" {
  source  = "./modules/security"
  env     = "DEV"
  project = "checkpoint-2"
  vpc_id  = module.network.vpc_id
}

module "alb_tier" {
  source              = "./modules/alb_tier"
  env                 = "DEV"
  project             = "checkpoint-2"
  security_groups_ids = [module.security.sg_alb_id]
  subnet_ids          = module.network.public_subnet_ids
  vpc_id              = module.network.vpc_id
}


module "compute_tier" {
  source  = "./modules/compute_tier"
  env     = "DEV"
  project = "checkpoint-2"
  app_security_group_ids = [
    module.security.sg_app_id
  ]
  # I need this ALB listener → target group → Auto Scaling Group → EC2 instances
  target_group_arns = [
    module.alb_tier.target_group_arn
  ]
  app_subnet_ids            = module.network.private_app_subnet_ids
  iam_instance_profile_name = module.security.app_instance_profile_name
}
