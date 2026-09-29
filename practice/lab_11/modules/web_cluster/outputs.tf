output "production_cluster_inventory" {
  description = "Map of AZ to Public IP"
  value = { for k, v in aws_instance.web_nodes : v.availability_zone => v.public_ip }
}