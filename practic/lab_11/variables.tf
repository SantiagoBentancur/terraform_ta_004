variable "app_instance_type" {
  type = string
}

variable "app_target_zone" {
  type = list(string)
}

variable "app_bucket" {
  type = string
}

variable "ami_id" {
  type        = string
  description = "Optional override for the AMI ID. If null, the latest Ubuntu AMI is used."
  default     = null
}