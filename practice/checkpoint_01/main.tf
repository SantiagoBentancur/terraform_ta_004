
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


data "aws_ami" "latest_ubuntu"{
  most_recent = true
  owners = ["099720109477"]

  filter {
    name = "Get ubuntu 22.04 - amd64 server"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]

  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]

  }

}
resource "aws_security_group" "web_traffic_rules" {
  name        = "web_traffic_rules"
  description = "Allow http and ssh traffic"

  # I got an error when I tried to apply the changes name for the security group. 
  # My fix was to add the lifecycle block with the create_before_destroy option set to true. 
  # This way, Terraform will create the new security group before destroying the old one, because aws does not allow to remove a security group that is in use by an instance.
  # lifecycle {
  #     create_before_destroy = true
  #   }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "web_nodes" {
  
  for_each = toset(var.target_zones)
  availability_zone = each.value
  
  ami = data.aws_ami.latest_ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.web_traffic_rules.id]
}

resource "aws_s3_bucket" "saa-backup-vault-prd" {
  bucket_prefix = "saa-backup-vault-"
  lifecycle {
    prevent_destroy = false
  }
}

output "production_cluster_inventory" {
  value = {for aws_instance in aws_instance.web_nodes : aws_instance.availability_zone => aws_instance.public_ip}
}