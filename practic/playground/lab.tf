provider "aws" {
  region = "us-east-1"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
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


resource "aws_instance" "web_nodes_v2" {
  
  ami = data.aws_ami.latest_ubuntu.id
  instance_type = var.instance_type

}

variable "test" {
  type = string
}

output "test" {
  value = var.test
}