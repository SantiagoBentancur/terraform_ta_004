# Lab 2: Multiple S3 Buckets with `count`

## Objective

Create three globally named S3 buckets from one resource block. This lab introduces `count`, `count.index`, the `format()` function, and the `aws_caller_identity` data source.

## Concepts to Practice

* Reading the current AWS account ID with a data source
* Creating multiple resource instances with `count`
* Using `count.index` inside resource arguments
* Constructing strings with `format()`
* Understanding numeric resource addresses

## Prerequisites

* Complete Lab 1.
* Review Sections 10–12, 17, and 19 in the theoretical README.
* Configure AWS credentials with permission to create and delete S3 buckets.

> **Cost and Cleanup Warning:** Empty S3 buckets generally have no meaningful storage cost, but you should still destroy all lab resources when finished.

## Requirements

Create the configuration in `lab_2.tf` without opening the solution first:

1. Configure the AWS provider to use `us-east-1`.
2. Declare a string variable named `bucket_prefix`.
   * Add a description.
   * Use `terraform-associate-lab2` as its default value.
3. Use the `aws_caller_identity` data source to obtain the current AWS account ID.
4. Declare one `aws_s3_bucket` resource named `lab`.
5. Configure the resource to create three instances with `count`.
6. Construct each bucket name with `format()` using, in this order:
   * The bucket-prefix variable
   * The AWS account ID
   * The current numeric index
7. Separate the three name components with hyphens.
8. Add `Name`, `Identifier`, and `ManagedBy` tags.
   * Include the current index in `Name`, example: "Lab 2 bucket <INDEX_COUNT>".
   * Convert the numeric index to a string for `Identifier`.
   * Set `ManagedBy` to `Terraform`.

The AWS account ID makes the name specific to your account, while the index makes the three names different. S3 uses a global bucket namespace by default, so each complete name must still be available.

## Execution Steps

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

## What to Observe

The plan should contain three numeric resource addresses:

```text
aws_s3_bucket.lab[0]
aws_s3_bucket.lab[1]
aws_s3_bucket.lab[2]
```

The value of `count.index` starts at zero and affects each bucket's name and tags.

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

variable "bucket_prefix" {
  description = "Base prefix for the S3 bucket names"
  type        = string
  default     = "terraform-associate-lab2"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "lab" {
  count = 3

  bucket = format(
    "%s-%s-%d",
    var.bucket_prefix,
    data.aws_caller_identity.current.account_id,
    count.index
  )

  tags = {
    Name       = "Lab 2 bucket ${count.index}"
    Identifier = tostring(count.index)
    ManagedBy  = "Terraform"
  }
}
```

</details>
