output "selected_environment" {
  description = "Final environment value selected by Terraform"
  value       = var.environment
}

output "selected_instance_count" {
  description = "Final instance count selected by Terraform"
  value       = var.instance_count
}

output "configuration_input" {
  description = "Input stored by the terraform_data resource"
  value       = terraform_data.configuration.output
}
