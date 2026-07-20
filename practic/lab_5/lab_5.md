# Lab 5: Stable VPC Identities with `for_each`

## Objective

Normalize inconsistent environment keys with a `for` expression and create one VPC per normalized key using `for_each`. This lab contrasts stable string identities with the numeric addresses used in Lab 4.

## Concepts to Practice

* Declaring a `map(object(...))` variable
* Transforming map keys with a `for` expression
* Normalizing strings with `lower()`, `trimspace()`, and `replace()`
* Declaring and referencing local values
* Creating resource instances with `for_each`
* Reading the current item with `each.key` and `each.value`

## Prerequisites

* Complete Labs 1–4.
* Review Sections 14, 16–17, and 20 in the theoretical README.
* Configure AWS credentials with permission to create and delete VPCs.

## Requirements

Create the configuration in `lab_5.tf` without opening the solution first:

1. Configure the AWS provider to use `us-east-1`.
2. Declare a variable named `network_environments` using `map(object(...))`.
3. Give every object one string attribute named `cidr`.
4. Define these deliberately inconsistent default keys and values:
   * `STAGE-environment ` with CIDR `10.1.0.0/16`
   * `PROD_Cluster-North ` with CIDR `10.2.0.0/16`
5. Declare a `locals` block containing a local value named `clean_environments`.
6. Build the local value with a map-producing `for` expression that:
   * Converts each key to lowercase.
   * Removes leading and trailing whitespace.
   * Replaces hyphens with underscores.
   * Preserves the object associated with each key.
7. Create an `aws_vpc` resource named `environment` using the normalized map with `for_each`.
8. Read the CIDR from the current object and use the current normalized key for the environment name.
9. Set `instance_tenancy` to `default`.
10. Add `Name`, `Environment`, and `ManagedBy` tags.
    * Prefix the `Name` value with `vpc-`.
    * Set `ManagedBy` to `Terraform`.
11. Declare an output named `normalized_environments` that displays the transformed map.

The normalization is a project naming convention, not an AWS requirement for VPC `Name` tags. It produces consistent keys that are easier to use as Terraform resource identities.

## Execution Steps

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

## What to Observe

The output should contain these normalized keys:

```text
prod_cluster_north
stage_environment
```

The resource instances are addressed by those keys:

```text
aws_vpc.environment["prod_cluster_north"]
aws_vpc.environment["stage_environment"]
```

Removing one key removes only the instance with that key. The remaining addresses do not shift, although Terraform can still update or replace a remaining instance if its own arguments change.

## Cleanup

```bash
terraform destroy
```

Review the destroy plan before confirming it.

## Solution

<details>
<summary>Show solution</summary>

```hcl
provider "aws" {
  region = "us-east-1"
}

variable "network_environments" {
  description = "VPC configurations with deliberately inconsistent input keys"
  type = map(object({
    cidr = string
  }))

  default = {
    "STAGE-environment " = {
      cidr = "10.1.0.0/16"
    }
    "PROD_Cluster-North " = {
      cidr = "10.2.0.0/16"
    }
  }
}

locals {
  clean_environments = {
    for key, value in var.network_environments :
    replace(trimspace(lower(key)), "-", "_") => value
  }
}

resource "aws_vpc" "environment" {
  for_each = local.clean_environments

  cidr_block       = each.value.cidr
  instance_tenancy = "default"

  tags = {
    Name        = "vpc-${each.key}"
    Environment = each.key
    ManagedBy   = "Terraform"
  }
}

output "normalized_environments" {
  description = "Environment map after key normalization"
  value       = local.clean_environments
}
```

</details>
