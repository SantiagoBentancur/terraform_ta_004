provider "aws" {
  region = "us-east-1"
}

module "network" {
  source          = "./modules/network"
  project_name    = var.project_name
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
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

resource "aws_security_group" "web_service" {
  name        = "web-service-security-group"
  description = "Security group for the EC2 consumer"
  vpc_id      = module.network.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-web-service"
  }
}

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.web_service.id
  description       = "Allow all outbound IPv4 traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "web_app" {
  ami                         = data.aws_ami.latest_linux_2023.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.web_service.id]
  subnet_id                   = module.network.public_subnet_ids[var.selected_public_subnet_key]
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-${var.environment}-web-app"
  }
}
