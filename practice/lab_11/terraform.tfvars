public_subnets = {
  public_a = {
    cidr              = "10.0.0.0/26"
    availability_zone = "us-east-1a"
  }
  public_b = {
    cidr              = "10.0.0.64/26"
    availability_zone = "us-east-1b"
  }
}

private_subnets = {
  private_a = {
    cidr              = "10.0.0.128/26"
    availability_zone = "us-east-1a"
  }
  private_b = {
    cidr              = "10.0.0.192/26"
    availability_zone = "us-east-1b"
  }
}
