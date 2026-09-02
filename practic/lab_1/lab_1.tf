provider "aws" {
  region = "us-east-1"
}

# Part 1
variable "environment" {
  description = "Environment used to name and tag the EC2 instance"
  type        = string
  default     = "development"
}

data "aws_ami" "amazon_linux_2023" {
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

output "selected_ami_id" {
  description = "Amazon Linux 2023 AMI selected by the data source"
  value       = data.aws_ami.amazon_linux_2023.id
}

# Part 2
resource "aws_instance" "application" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  tags = {
    "Name"        = "${var.environment}-application-server"
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}

output "instance_id" {
  description = "ID of the EC2 instance created by this lab"
  value       = aws_instance.application.id
}
