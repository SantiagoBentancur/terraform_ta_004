# Lab 4: Indexing a Map with `count`

## Objective

Create one VPC for each object in a map while deliberately using numeric `count` indexes. This demonstrates how `keys()` and `values()` can bridge a map to `count`, and prepares you to compare numeric identities with `for_each` in Lab 5.

## Concepts to Practice

* Declaring a `map(object(...))` variable
* Calculating instance count with `length()`
* Reading lexicographically ordered map keys with `keys()`
* Reading values in the corresponding order with `values()`
* Addressing resource instances by numeric index

## Prerequisites

* Complete Labs 1–3.
* Review Sections 11, 14, 17, and 19 in the theoretical README.
* Configure AWS credentials with permission to create and delete VPCs.

## Requirements

Create the configuration in `lab_4.tf` without opening the solution first:

1. Configure the AWS provider to use `us-east-1`.
2. Declare a variable named `environments` using `map(object(...))`.
3. Give every object one string attribute named `cidr`.
4. Define two default map elements:
   * `staging` with CIDR `10.1.0.0/16`
   * `production` with CIDR `10.2.0.0/16`
5. Create one `aws_vpc` resource named `environment`.
6. Set `count` to the number of elements in the map.
7. For each numeric index:
   * Obtain the CIDR from the corresponding entry returned by `values()`.
   * Obtain the environment name from the corresponding entry returned by `keys()`.
8. Set `instance_tenancy` to `default`.
9. Add `Name`, `Environment`, and `ManagedBy` tags.
   * Prefix the `Name` value with `vpc-`.
   * Set `ManagedBy` to `Terraform`.

Terraform's `keys()` function returns map keys in lexicographical order. For the required map, the ordered keys are:

```text
["production", "staging"]
```

`values()` follows the same key order, so a key and CIDR selected with the same `count.index` remain paired.

## Execution Steps

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

## What to Observe

The state addresses use numeric identities:

```text
aws_vpc.environment[0]
aws_vpc.environment[1]
```

The addresses do not include the environment names. If the ordered keys change, a numeric address may become associated with a different environment configuration. Lab 5 replaces these numeric identities with stable map keys.

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

variable "environments" {
  description = "VPC configuration indexed indirectly through count"
  type = map(object({
    cidr = string
  }))

  default = {
    staging = {
      cidr = "10.1.0.0/16"
    }
    production = {
      cidr = "10.2.0.0/16"
    }
  }
}

resource "aws_vpc" "environment" {
  count = length(var.environments)

  cidr_block       = values(var.environments)[count.index].cidr
  instance_tenancy = "default"

  tags = {
    Name        = "vpc-${keys(var.environments)[count.index]}"
    Environment = keys(var.environments)[count.index]
    ManagedBy   = "Terraform"
  }
}
```

</details>
