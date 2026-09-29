
variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "env" {
  type = string
}

variable "project" {
  type    = string
  default = "checkpoint-2"
}
