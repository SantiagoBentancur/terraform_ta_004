variable "app_target_zone" {
  type = list(string)
  default = [ "us-east-1a" ,"us-east-1b"]
}


variable "app_instance_type" {
 type = string
 default = "t2.micro"
}

variable "app_bucket" {
  type = string
  default = "saa-backup-vault-"
}