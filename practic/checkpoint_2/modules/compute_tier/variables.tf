variable "azs" {
  description = "Availability Zones used by the compute tier resources."
  type        = map(string)

  default = {
    az_1 = "us-east-1a"
    az_2 = "us-east-1b"
  }
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
