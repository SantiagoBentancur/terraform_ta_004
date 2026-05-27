# 🛠️ Lab 5 The Automated Network Topology (Advanced)

## Concepts to Practice
* `for_each` loops
* `local` variables
* String manipulation functions: `lower()`, `trimspace()`, `replace()`
* Nested Data Structures: `map(object({}))`

---

## Objective
Deploy a series of isolated AWS Virtual Private Clouds (VPCs) dynamically based on a complex nested configuration map, while automatically sanitizing messy human input errors using standard string functions and local variables.

---

## The Requirements

### 1. The Human Map Variable
Create a map of objects variable named `network_environments`. It contains raw, unformatted target environments as keys and their corresponding CIDR blocks as values. Deliberately use messy formatting (uppercase, spaces, hyphens) to simulate bad user input.

```hcl
variable "network_environments" {
  type = map(object({
    cidr = string
  }))
  default = {
    "STAGE-environment "  = { cidr = "10.1.0.0/16" }
    "PROD_Cluster-North " = { cidr = "10.2.0.0/16" }
  }
}
```

### 2. The Local Variable Sanitizer (Functions Prep)
AWS requires resource names to be lowercase and free of spaces. Create a `locals` block that uses a `for` expression to clean up the keys:
* Use `lower()` to make the environment names lowercase.
* Use `trimspace()` to remove trailing spaces.
* Use `replace()` to convert hyphens into clean underscores (`_`).
* Keep the data objects intact using the `=> v` assignment pointer.

### 3. The `aws_vpc` Resource via `for_each`
* Instead of `count`, use `for_each` pointing to your sanitized local map (`local.clean_environments`).
* Set the `cidr_block` argument using the object values via `each.value.cidr`.
* In the `tags`, use the native `each.key` context to name your VPCs cleanly.

---

## Key Architectural Features
1. **Input Sanitization (`locals`):** Decouples human-facing input variables from strict cloud provider naming constraints by processing data dynamically before resource execution.
2. **Identity-Based Scaling (`for_each`):** Replaces `count` to track resources by explicit string keys (e.g., `stage_environment`) rather than integer array positions, making the infrastructure completely immune to middle-list deletion shifts.
3. **Object Expansion:** Uses `map(object)` schemas to attach multiple configuration parameters to a single environment key, allowing future expansion without rewriting the core loop logic.

---

## Terraform Code (`lab_5.tf`)

```hcl
provider "aws" {
  region = "us-east-1"
}

# 1. Variable with messy, human-typed keys
variable "network_environments" {
  type = map(object({
    cidr = string
  }))
  default = {
    "STAGE-environment"   = { cidr = "10.1.0.0/16" }
    "PROD_Cluster-North " = { cidr = "10.2.0.0/16" }
  }
}

# 2. Local block to clean strings while preserving data objects
locals {
  clean_environments = {
    for k, v in var.network_environments : replace(trimspace(lower(k)), "-", "_") => v
  }
}

# 3. Output to audit the data transformation
output "env" {
  value = local.clean_environments
}

# 4. Target VPC deployment using for_each
resource "aws_vpc" "main" {
  for_each         = local.clean_environments
  
  cidr_block       = each.value.cidr
  instance_tenancy = "default"

  tags = {
    Name = "vpc-${each.key}"
  }
}
```

---

## Step-by-Step Implementation Guide

Follow these steps to validate how `for_each` parses sanitized data structures:

#### Step 1: Initialize the Working Directory
Prepare your local terminal directory so that Terraform can fetch the necessary AWS provider binaries.
```bash
terraform init
```

#### Step 2: Validate Data Transformation via Outputs
Before checking the resource creation, ensure your local block correctly transformed the messy strings into clean keys. 
* Execute `terraform apply` or `terraform plan` and check the `env` output block.
* You should see exactly this transformation map:
  ```json
  {
    "stage_environment"  = { cidr = "10.1.0.0/16" }
    "prod_cluster_north" = { cidr = "10.2.0.0/16" }
  }
  ```

#### Step 3: Execute and Validate State Targets
Verify how `for_each` maps the resources to your clean string keys rather than integers.
```bash
terraform plan
```
* **Verify Resource Identifiers:** Inspect your terminal plan log carefully. You will see that the VPCs are registered permanently in state under their explicit string identities, rendering them completely immune to array shifts:
  * `aws_vpc.main["stage_environment"]`
  * `aws_vpc.main["prod_cluster_north"]`