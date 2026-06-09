terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.47.0" 
    }
  }
  required_version = ">= 1.14.7" 
}

resource "aws_security_group" "web_traffic_rules" {
  name        = "web_traffic_rules"
  description = "Allow http and ssh traffic"

  lifecycle {
      create_before_destroy = true
    }

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
  
  ami = var.ami
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.web_traffic_rules.id]
}