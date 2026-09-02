variable "security_groups_ids" {
  description = "List of security group IDs to associate with the Application Load Balancer."
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of public subnet IDs in which to deploy the Application Load Balancer"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC in which to create the ALB target group"
  type        = string
}

variable "env" {
  description = "Deployment environment name used for resource naming and tagging"
  type        = string
}

variable "project" {
  description = "Project name used for resource tagging"
  type        = string
  default     = "checkpoint-2"
}
