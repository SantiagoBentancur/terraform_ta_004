
variable "vpc_id" {
  description = "ID of the VPC where the security groups are created."
  type        = string
}

variable "env" {
  description = "Deployment environment used for naming and tagging security resources."
  type        = string
}

variable "project" {
  description = "Project name used for naming and tagging security resources."
  type        = string
  default     = "checkpoint-2"
}
