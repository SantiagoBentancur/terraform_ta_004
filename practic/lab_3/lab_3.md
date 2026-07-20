# Lab 3: Conditional Infrastructure

## Objective

Change the number and size of EC2 instances with one Boolean input. This lab combines conditional expressions, explicit type conversion, map lookup, and `count`.

## Concepts to Practice

* Declaring a Boolean input variable
* Selecting values with a conditional expression
* Converting a Boolean with `tostring()`
* Looking up a value in a map
* Setting `count` conditionally
* Using `count.index` in resource names

## Prerequisites

* Complete Labs 1 and 2.
* Review Sections 10–12, 17, and 19 in the theoretical README.
* Configure AWS credentials with permission to create and terminate EC2 instances.

> **Cost Warning:** This lab creates one or two EC2 instances. Run `terraform destroy` when you finish.

## Requirements

Create the configuration in `lab_3.tf` without opening the solution first:

1. Configure the AWS provider to use `us-east-1`.
2. Declare a Boolean variable named `is_production` with a default value of `false`.
3. Declare a `map(string)` variable named `instance_types`.
   * Map the string key `true` to `t3.small`.
   * Map the string key `false` to `t3.micro`.
4. Declare an `aws_ami` data source named `amazon_linux_2023` using the same Amazon Linux 2023 owner and filters practised in Lab 1.
5. Create an `aws_instance` resource named `environment_server`.
6. Use a conditional expression for `count`:
   * Create two instances in production.
   * Create one instance otherwise.
7. Select the instance type from `var.instance_types`.
   * Convert the Boolean value to a string before using it as the map key.
8. Add `Name`, `Environment`, and `ManagedBy` tags.
   * Use `prod` or `dev` in the name according to the Boolean input.
   * Append `count.index` to make each name identifiable.
   * Use the full word `production` or `development` for the `Environment` tag.

## Execution Steps

Start with the default development configuration:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Then preview the production configuration without editing the file:

```bash
terraform plan -var='is_production=true'
```

## What to Observe

With `is_production = false`, Terraform manages one `t3.micro` instance:

```text
aws_instance.environment_server[0]
```

With `is_production = true`, the desired configuration contains two `t3.small` instances. The first instance retains address `[0]`, while Terraform adds address `[1]`. Terraform updates or replaces an existing instance only when the changed provider argument requires that behavior.

The instance-type map is intentionally educational. A direct conditional could also select the size, but the map demonstrates `tostring()` and typed lookup.

## Cleanup

If you applied only the default configuration:

```bash
terraform destroy
```

If you applied with `is_production=true`, pass the same value during destroy:

```bash
terraform destroy -var='is_production=true'
```

## Solution

<details>
<summary>Show solution</summary>

```hcl
provider "aws" {
  region = "us-east-1"
}

variable "is_production" {
  description = "Whether to use the production instance count and size"
  type        = bool
  default     = false
}

variable "instance_types" {
  description = "Instance type selected from the string form of is_production"
  type        = map(string)
  default = {
    "true"  = "t3.small"
    "false" = "t3.micro"
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "environment_server" {
  count = var.is_production ? 2 : 1

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_types[tostring(var.is_production)]

  tags = {
    Name        = "server-${var.is_production ? "prod" : "dev"}-${count.index}"
    Environment = var.is_production ? "production" : "development"
    ManagedBy   = "Terraform"
  }
}
```

</details>
