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


data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


module "web_cluster" {

  source = "./modules/web_cluster"
  name = "web-node"
  ami = data.aws_ami.latest_ubuntu.id
  instance_type = var.app_instance_type
  target_zones = var.app_target_zone

}


module "storage_vault" {
  source = "./modules/storage_vault"
  bucket_prefix = var.app_bucket
  # prevent_destroy = var.prevent_destroy
  
}


output "cluster_inventory" {
  description = "The inventory of the web cluster"
  value       = module.web_cluster.production_cluster_inventory
}


