variable "azs" {
  type = map(string)

  default = {
    az_1 = "us-east-1a"
    az_2 = "us-east-1b"
  }
}


variable "subnet_cidrs" {
  type = map(string)

  default = {
    public_1 = "10.0.1.0/24"
    public_2 = "10.0.2.0/24"
    app_1    = "10.0.10.0/24"
    app_2    = "10.0.20.0/24"
    db_1     = "10.0.30.0/24"
    db_2     = "10.0.40.0/24"
  }
}


variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "env" {
  type = string
}

variable "project" {
  type    = string
  default = "checkpoint-2"
}
