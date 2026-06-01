provider "aws" {
  region = "us-east-1"
}



data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

}

output "ami_encontrada_id" {
  value = data.aws_ami.amazon_linux_2.id
}

variable "environment" {
  type        = map(string)
  description = "my env"
  default = {
    dev  = "Development"
    prod = "Production"
  }
}



resource "aws_instance" "ec2_lab1" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  tags = {
    Name = var.environment["prod"]
  }

}


