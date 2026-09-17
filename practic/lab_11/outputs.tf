output "vpc_id" {
  description = "ID of the VPC created by the network module"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs keyed by input name"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs keyed by input name"
  value       = module.network.private_subnet_ids
}

output "instance_id" {
  description = "ID of the EC2 consumer instance"
  value       = aws_instance.web_app.id
}

output "instance_public_ip" {
  description = "Public IPv4 address of the EC2 consumer instance"
  value       = aws_instance.web_app.public_ip
}
