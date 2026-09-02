# Lab 0: Terraform Workflow and Variable Precedence

## Objective

Learn how Terraform loads configuration files, declares and assigns variables, resolves variable precedence, exposes outputs, and records state. This lab uses the built-in `terraform_data` resource, so it requires no cloud credentials and creates no billable infrastructure.

## Concepts to Practice

* Organizing a Terraform configuration across multiple `.tf` files
* Distinguishing `variables.tf` from `.tfvars` files
* Understanding automatically loaded and explicitly selected variable files
* Overriding values with `TF_VAR_*`, `-var-file`, and `-var`
* Running `init`, `fmt`, `validate`, `plan`, `apply`, `output`, and `destroy`
* Inspecting Terraform state

## Project Structure

```text
lab_0/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── development.tfvars
└── lab_0.md
```

Terraform reads all `.tf` files in the current working directory as one configuration. Filenames such as `main.tf`, `variables.tf`, and `outputs.tf` are organizational conventions; they do not control execution order. References and the dependency graph determine operation order.

## File Responsibilities

### `variables.tf`

This file declares the accepted inputs, their types, descriptions, and default values:

```hcl
variable "environment" {
  description = "Environment selected for this configuration"
  type        = string
  default     = "from-variable-default"
}

variable "instance_count" {
  description = "Example numeric input used to demonstrate variable precedence"
  type        = number
  default     = 1
}
```

### `terraform.tfvars`

Terraform loads this filename automatically:

```hcl
environment    = "from-terraform-tfvars"
instance_count = 2
```

### `development.tfvars`

Terraform does not load an arbitrary `.tfvars` filename automatically. Select this file with `-var-file`:

```hcl
environment    = "from-development-tfvars"
instance_count = 3
```

### `main.tf`

The built-in `terraform_data` resource stores the final values selected by Terraform:

```hcl
resource "terraform_data" "configuration" {
  input = {
    environment    = var.environment
    instance_count = var.instance_count
  }
}
```

### `outputs.tf`

Outputs expose the selected values and the resource result:

```hcl
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
```

## Phase 1: Initialize and Validate

Run these commands from `practic/lab_0`:

```bash
terraform init
terraform fmt -check
terraform validate
```

`terraform init` prepares the working directory. This lab does not download a cloud provider because `terraform_data` is built into Terraform.

## Phase 2: Use Automatically Loaded Values

Run:

```bash
terraform plan
terraform apply
```

Because `terraform.tfvars` is loaded automatically, the outputs should include:

```text
selected_environment    = "from-terraform-tfvars"
selected_instance_count = 2
```

The defaults in `variables.tf` are not selected because `terraform.tfvars` has higher precedence.

## Phase 3: Select a Custom Variable File

Run:

```bash
terraform plan -var-file="development.tfvars"
```

The plan should use:

```text
selected_environment    = "from-development-tfvars"
selected_instance_count = 3
```

Values from the explicitly selected `development.tfvars` file override values from the automatically loaded `terraform.tfvars` file.

## Phase 4: Override One Value with `-var`

Run:

```bash
terraform plan \
  -var-file="development.tfvars" \
  -var="environment=from-command-line"
```

The final values should be:

```text
selected_environment    = "from-command-line"
selected_instance_count = 3
```

The later `-var` option overrides `environment`, while `instance_count` still comes from `development.tfvars`.

## Phase 5: Test an Environment Variable

On Linux or macOS, run:

```bash
export TF_VAR_environment="from-environment-variable"
terraform plan
```

The result remains `from-terraform-tfvars` because automatically loaded `.tfvars` values have higher precedence than `TF_VAR_*` environment variables.

Remove the environment variable when the test is complete:

```bash
unset TF_VAR_environment
```

## Phase 6: Inspect Outputs and State

After applying the default command from Phase 2, run:

```bash
terraform output
terraform output selected_environment
terraform state list
terraform state show terraform_data.configuration
```

The state list should contain:

```text
terraform_data.configuration
```

State connects the resource address in the configuration to the managed resource instance. Do not edit the state file manually.

## Variable Precedence Used in This Lab

From lower to higher precedence:

1. Default values in `variables.tf`
2. `TF_VAR_*` environment variables
3. `terraform.tfvars`
4. Explicit `-var-file` and `-var` options, processed in command-line order

Terraform also supports `terraform.tfvars.json` and automatically loaded `*.auto.tfvars` files, which are explained in Section 10 of the main README.

## Cleanup

Run:

```bash
terraform destroy
```

Then confirm that the state no longer contains the resource:

```bash
terraform state list
```

## Exam Takeaways

* `.tf` files define one combined configuration; their filenames do not set execution order.
* `variables.tf` declares variables but does not receive special loading behavior because of its filename.
* `terraform.tfvars` is loaded automatically.
* Custom filenames such as `development.tfvars` require `-var-file`.
* A later `-var` can override a value supplied by an earlier `-var-file`.
* Outputs expose evaluated values, while state records managed resource instances.
* `terraform plan` previews changes; `terraform apply` performs them.
