variable "instance_type" {
  type = string
  
    validation {
      condition = var.instance_type == "t2.micro" || var.instance_type == "t3.micro"
      error_message = "The instance type must be either 't2.micro' or 't3.micro'."
    }
  default = "t3.micro"
}


variable "target_zones" {
    type = list(string)
    default = ["us-east-1a", "us-east-1b"]
  
}