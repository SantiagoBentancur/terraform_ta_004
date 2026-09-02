resource "terraform_data" "configuration" {
  input = {
    environment    = var.environment
    instance_count = var.instance_count
  }
}
