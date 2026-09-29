terraform {
  required_version = ">= 1.11.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

variable "parameter_value" {
  description = "The value of the parameter to be created"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "secret_version" {
  type    = number
  default = 1

  validation {
    condition     = var.secret_version > 0 && floor(var.secret_version) == var.secret_version
    error_message = "secret_version must be a positive whole number."
  }
}


resource "aws_ssm_parameter" "secret" {
  name        = "/lab16/application-secret"
  description = "Disposable Lab 16 application secret"
  type        = "SecureString"

  value_wo         = var.parameter_value
  value_wo_version = var.secret_version
}

output "parameter_arn" {
  value       = aws_ssm_parameter.secret.arn
  description = "ARN of the SSM parameter"
}

output "secret_version" {
  value       = var.secret_version
  description = "Non-secret version used to signal rotation"
}
