terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0"
      configuration_aliases = [aws.primary, aws.secondary]
    }
  }
}

data "aws_availability_zones" "available_east" {
  provider = aws.primary
  state    = "available"
}

data "aws_availability_zones" "available_west" {
  provider = aws.secondary
  state    = "available"
}
