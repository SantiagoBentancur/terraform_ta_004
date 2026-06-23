variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_1" {
  type    = string
  default = "us-east-1a"
}

variable "az_2" {
  type    = string
  default = "us-east-1b"
}

variable "public_subnet_1_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "app_subnet_1_cidr" {
  type    = string
  default = "10.0.10.0/24"
}

variable "app_subnet_2_cidr" {
  type    = string
  default = "10.0.20.0/24"
}

variable "db_subnet_1_cidr" {
  type    = string
  default = "10.0.30.0/24"
}

variable "db_subnet_2_cidr" {
  type    = string
  default = "10.0.40.0/24"
}

variable "env" {
  type = string
}

variable "project" {
  type    = string
  default = "checkpoint-2"
}
