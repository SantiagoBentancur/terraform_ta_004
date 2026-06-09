
variable "name" {
  description = "Name to be used on EC2 instance created"
  type        = string
  default     = ""
}

variable "region" {
  description = "Region where the resource(s) will be managed. Defaults to the Region set in the provider configuration"
  type        = string
  default     = null
}

variable "ami" {
  description = "ID of AMI to use for the instance"
  type        = string
  default     = null
}

variable "instance_type" {
  type = string
  
    validation {
      condition     = contains(["t2.micro", "t3.micro"], var.instance_type) # I changed to contains 
      error_message = "The instance type must be either 't2.micro' or 't3.micro'."
    }
}

variable "target_zones" {
    description = "Target availability zones for the EC2 instances"
    type = list(string)  
}


variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with an instance in a VPC"
  type        = bool
  default     = null
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = []
}