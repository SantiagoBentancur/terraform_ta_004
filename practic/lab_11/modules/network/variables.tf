
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
  type    = string
  default = "lab_11"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/24"
}
