

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = {
    for key, subnet in aws_subnet.public_subnets : key => subnet.id
  }
}

output "private_subnet_ids" {
  value = {
    for key, subnet in aws_subnet.private_subnets : key => subnet.id
  }
}
