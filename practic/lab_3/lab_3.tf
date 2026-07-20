provider "aws" {
  region = "us-east-1"
}

variable "is_production" {
  description = "Whether to use the production instance count and size"
  type        = bool
  default     = false
}

variable "instance_types" {
  description = "Instance type selected from the string form of is_production"
  type        = map(string)
  default = {
    "true"  = "t3.small"
    "false" = "t3.micro"
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "environment_server" {
  count = var.is_production ? 2 : 1

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_types[tostring(var.is_production)]

  tags = {
    Name        = "server-${var.is_production ? "prod" : "dev"}-${count.index}"
    Environment = var.is_production ? "production" : "development"
    ManagedBy   = "Terraform"
  }
}
