variable "environment" {
  description = "Environment selected for this configuration"
  type        = string
  default     = "from-variable-default"
}

variable "instance_count" {
  description = "Example numeric input used to demonstrate variable precedence"
  type        = number
  default     = 1
}
