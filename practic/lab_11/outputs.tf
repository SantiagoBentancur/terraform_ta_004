output "cluster_inventory" {
  description = "The inventory of the web cluster"
  value       = module.web_cluster.production_cluster_inventory
}
