terraform {
  required_version = ">= 1.10.0"
  backend "s3" {
    key          = "labs/lab14/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

resource "terraform_data" "workspace_record" {
  input = {
    workspace = terraform.workspace
  }
}

output "workspace_record" {
  value = terraform_data.workspace_record.output
}

output "current_workspace" {
  value = terraform.workspace
}
