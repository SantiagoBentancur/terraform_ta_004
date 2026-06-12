
variable "name" {
  description = "Name to be used on EC2 instance created"
  type        = string
  default     = ""
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
  default     = "t2.micro"

}

variable "target_zones" {
    description = "Target availability zones for the EC2 instances"
    type = list(string)  
}
