variable "public_subnets" {
  type = map(object({
    cidr              = string
    availability_zone = string
  }))
}

variable "private_subnets" {
  type = map(object({
    cidr              = string
    availability_zone = string
  }))
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
  default     = "lab_11"
}

variable "environment" {
  type        = string
  description = "Environment name used for resource naming"
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block assigned to the child module VPC"
  default     = "10.0.0.0/24"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the consumer"
  default     = "t3.micro"
}

variable "selected_public_subnet_key" {
  type        = string
  description = "Key of the public subnet where the EC2 instance will be placed"
  default     = "public_a"
}
