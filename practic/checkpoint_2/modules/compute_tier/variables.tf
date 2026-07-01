variable "azs" {
  type = map(string)

  default = {
    az_1 = "us-east-1a"
    az_2 = "us-east-1b"
  }
}
