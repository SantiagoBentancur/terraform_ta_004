

provider "aws" {
  region = "us-east-1"
}

variable "is_production" {
  type        = bool
  description = "Toggles a specific feature on or off"
  default     = false
}

variable "instance_types" {
  type = map(string)
  default = {
    "true"  = "t3.small"
    "false" = "t3.micro"
  }

}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }

}


resource "aws_instance" "ec2_lab1" {
  ami           = data.aws_ami.amazon_linux_2.id
  count         = var.is_production ? 2 : 1
  instance_type = var.instance_types[tostring(var.is_production)]
  tags = {
    Name = "server-${var.is_production ? "prod" : "dev"}-${count.index}"
  }

}

