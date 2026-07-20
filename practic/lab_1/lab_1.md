# Lab 1: Dynamic AMI Discovery

## Objective

Deploy one EC2 instance using an Amazon Linux 2023 AMI discovered through an AWS data source. This lab introduces the relationship between provider configuration, input variables, data sources, managed resources, references, and outputs.

## Concepts to Practice

* Configuring the AWS provider
* Declaring and referencing a string input variable
* Reading existing information with a `data` block
* Creating infrastructure with a `resource` block
* Using a data-source attribute as a resource argument
* Exposing values with `output` blocks

## Prerequisites

* Complete Lab 0.
* Review Sections 2, 9–12, and 17 in the theoretical README.
* Confirm that Terraform is installed.
* Configure AWS credentials outside the Terraform code.
* Ensure the credentials can create and terminate EC2 instances in `us-east-1`.

> **Cost Warning:** This lab creates an EC2 instance. Run `terraform destroy` when you finish.

## Requirements

Create the configuration in `lab_1.tf` without opening the solution first:

1. Configure the AWS provider to use `us-east-1`.
2. Declare a string variable named `environment`. Give it a useful description and set its default to `development`.
3. Declare an `aws_ami` data source named `amazon_linux_2023`.
   * Select the most recent image.
   * Restrict the owner to Amazon.
   * Filter the image name with `al2023-ami-2023.*-kernel-6.1-x86_64`.
   * Add a second filter that accepts only images whose state is `available`.
4. Create one `aws_instance` resource named `application`.
   * Use the AMI ID returned by the data source.
   * Use `t3.micro` as the instance type.
   * Add `Name`, `Environment`, and `ManagedBy` tags.
   * Build the `Name` tag from the environment value followed by `-application-server`.
5. Declare an output named `selected_ami_id` containing the AMI ID.
6. Declare an output named `instance_id` containing the EC2 instance ID.
7. Add descriptions to both outputs.

## Execution Steps

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

After the apply, confirm that Terraform displays `selected_ami_id` and `instance_id`.

## What to Observe

* The `data` block reads an existing AMI; it does not create the AMI.
* The `aws_instance` resource creates and manages the EC2 instance.
* Referencing the AMI data-source attribute connects the selected image to the instance configuration.
* The `environment` input is a string because this first AWS lab does not need a collection.

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

variable "environment" {
  description = "Environment name used to tag the EC2 instance"
  type        = string
  default     = "development"
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

resource "aws_instance" "application" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  tags = {
    Name        = "${var.environment}-application-server"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

output "selected_ami_id" {
  description = "Amazon Linux 2023 AMI selected by the data source"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "instance_id" {
  description = "ID of the EC2 instance created by this lab"
  value       = aws_instance.application.id
}
```

</details>
