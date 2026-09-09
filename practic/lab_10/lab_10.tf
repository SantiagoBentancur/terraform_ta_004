provider "aws" {
  region = "us-east-1"
}

variable "key_pair_name" {
  type        = string
  description = "Name of the EC2 key pair registered in us-east-1"
}

variable "private_key_path" {
  type        = string
  description = "Path to the matching private SSH key on the Terraform operator machine"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR block allowed to connect to SSH"
}

variable "server_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

data "aws_ami" "latest_linux_2023" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

resource "aws_security_group" "web_server" {
  name        = "lab-10-web-server"
  description = "Security rules for the Lab 10 web server"
  vpc_id      = data.aws_vpc.default_vpc.id

  tags = {
    Name = "lab-10-web-server"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web_server.id
  description       = "Allow SSH from the operator IP range"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.allowed_ssh_cidr
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web_server.id
  description       = "Allow HTTP traffic"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.web_server.id
  description       = "Allow all outbound IPv4 traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.latest_linux_2023.id
  instance_type               = var.server_type
  subnet_id                   = sort(data.aws_subnets.default_vpc.ids)[0]
  vpc_security_group_ids      = [aws_security_group.web_server.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
      private_key = file(var.private_key_path)
    }

    inline = [
      "sudo dnf install -y nginx",
      "sudo systemctl enable --now nginx",
    ]
  }

  provisioner "local-exec" {
    command = "echo 'created ${self.id} ${self.public_ip}' > server_info.txt"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'destroyed ${self.id}' >> server_info.txt"
  }
}

output "default_vpc_id" {
  description = "ID of the existing default VPC used by the lab"
  value       = data.aws_vpc.default_vpc.id
}

output "application_url" {
  description = "HTTP URL for the Nginx web server"
  value       = "http://${aws_instance.web_server.public_ip}"
}
