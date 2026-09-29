variable "azs" {
  description = "Availability Zones used by the compute tier resources."
  type        = map(string)

  default = {
    az_1 = "us-east-1a"
    az_2 = "us-east-1b"
  }
}

variable "app_subnet_ids" {
  description = "IDs of the private application subnets used by the Auto Scaling Group."
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile attached to application EC2 instances."
  type        = string
}


variable "env" {
  description = "Deployment environment used to select environment-specific compute settings."
  type        = string

  validation {
    condition     = var.env == "DEV" || var.env == "PRD"
    error_message = "The env must be either DEV or PRD."
  }
}


variable "type_instance" {
  description = "Map of EC2 instance types used by the launch template for each environment."
  type        = map(string)
  default = {
    "DEV" = "t3.micro"
    "PRD" = "t3.small"
  }

}

variable "ubuntu_version" {
  description = "The Ubuntu version to deploy (e.g., 22.04 or 24.04)"
  type        = string
  default     = "22.04"
}

variable "ubuntu_codename" {
  description = "The OS codename (e.g., jammy for 22.04, noble for 24.04)"
  type        = string
  default     = "jammy"
}


variable "project" {
  description = "Project name used for resource tagging"
  type        = string
  default     = "checkpoint-2"
}

variable "app_security_group_ids" {
  description = "Security group IDs attached to application instances"
  type        = list(string)
}

variable "target_group_arns" {
  description = "ALB target group ARNs attached to the Auto Scaling Group"
  type        = list(string)
}

variable "auto_scaling_set_up" {
  type = map(object({
    max_size = number, min_size = number, health_check_grace_period = number, health_check_type = string, desired_capacity = number
    }
  ))
  default = {
    "DEV" = {
      "max_size"                  = 2
      "min_size"                  = 1
      "health_check_grace_period" = 300
      "health_check_type"         = "ELB"
      "desired_capacity"          = 1
    }
    "PRD" = {
      "max_size"                  = 3
      "min_size"                  = 2
      "health_check_grace_period" = 300
      "health_check_type"         = "ELB"
      "desired_capacity"          = 2
    }
  }
}
