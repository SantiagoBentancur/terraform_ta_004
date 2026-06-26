variable "security_groups_ids" {
  type = list(string)

}

variable "subnet_ids" {
  type = list(any)
}

variable "vpc_id" {
  type = string
}

variable "env" {
  type = string
}

variable "project" {
  type    = string
  default = "checkpoint-2"
}