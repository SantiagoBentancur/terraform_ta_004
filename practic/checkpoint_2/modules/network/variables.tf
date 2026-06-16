variable "vpc_cdr" {
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

variable "cdr_pub_subnet_1" {
  type    = string
  default = "10.0.1.0/24"
}

variable "cdr_pub_subnet_2" {
  type    = string
  default = "10.0.2.0/24"
}

variable "cdr_app_1" {
  type    = string
  default = "10.0.10.0/24"
}

variable "cdr_app_2" {
  type    = string
  default = "10.0.20.0/24"
}

variable "cdr_db_1" {
  type    = string
  default = "10.0.30.0/24"
}

variable "cdr_db_2" {
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
