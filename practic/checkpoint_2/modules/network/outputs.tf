output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets used by the ALB"
  value = [
  aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets used by the ASG"
  value = [aws_subnet.app_1.id, aws_subnet.app_2.id
  ]
}