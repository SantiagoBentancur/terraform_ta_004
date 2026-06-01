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

resource "aws_security_group" "web_traffic_rules" {
  name        = "allow_tls"
  description = "Allow http and ssh traffic"

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


}

resource "aws_s3_bucket" "saa-backup-vault-prd" {
  bucket = "saa-backup-vault-prd"
  
  lifecycle {
    prevent_destroy = true
  }
}

output "production_cluster_inventory" {
  value = {for aws_instance in aws_instance.web_nodes : aws_instance.availability_zone => aws_instance.public_ip}
}