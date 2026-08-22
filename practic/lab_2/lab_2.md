# Lab 2: Multiple S3 Buckets with `count`

## Objective

Create multiple S3 buckets from one resource block. First, read the current AWS account identity and build globally distinctive names. Then, use `count` and `count.index` to create and address three numeric resource instances.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Completed.

**[View my Terraform solution](./lab_2.tf)**

When completed, this implementation should:

* Read the current AWS account ID.
* Create three S3 buckets through one resource block.
* Build unique names and tags from `count.index`.
* Demonstrate numeric resource-instance addresses.

Validation commands:

```bash
terraform fmt -check
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Reading account metadata through a data source
* Creating multiple instances with `count`
* Reading the current numeric index
* Constructing strings with `format()`
* Converting a number to a string
* Understanding numeric resource addresses

## Prerequisites

* Review [`count`](../../README.md#the-count-meta-argument), [Data Sources](../../README.md#data-sources-data-blocks), and [String and Conversion Functions](../../README.md#string-and-conversion-functions).
* Configure AWS credentials with permission to create and delete S3 buckets.

> **Cleanup Warning:** S3 bucket names use a global namespace. Destroy every empty lab bucket when finished.

## Step-by-Step Requirements

Build the configuration in `lab_2.tf` in the order shown below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Read the Account Identity</strong></summary>

<details>
<summary>Why the account ID is part of the name</summary>

S3 bucket names must be globally unique within the standard AWS partitions. Adding the current account ID makes the name account-specific, while a numeric suffix distinguishes the three buckets in this lab. Availability is still not mathematically guaranteed, so choose a different prefix if a collision occurs.

</details>

1. Configure the AWS provider to use `us-east-1`.
2. Declare a string variable named `bucket_prefix`.
   * Add a description.
   * Default it to `terraform-associate-lab2`.
3. Use `aws_caller_identity` to obtain the current account ID.

Run `terraform init` and `terraform validate` before continuing.

</details>

<details>
<summary><strong>Part 2: Create and Inspect the Counted Buckets</strong></summary>

4. Declare one `aws_s3_bucket` resource named `lab`.
5. Configure it to create three instances with `count`.
6. Construct each bucket name with `format()` using, in order:
   * The prefix variable.
   * The AWS account ID.
   * The current numeric index.
7. Separate those components with hyphens.
8. Add these tags:
   * `Name` using the hyphenated format `lab-2-bucket-<index>`, where `<index>` is the string representation of the current `count.index` value.
   * `Identifier` as the string form of the current index.
   * `ManagedBy` as `Terraform`.

Run:

```bash
terraform fmt
terraform validate
terraform plan
```

Confirm that:

* The plan proposes exactly three buckets.
* Their addresses are `aws_s3_bucket.lab[0]`, `[1]`, and `[2]`.
* Every bucket name is different.
* `Identifier` is a string, not a number.
* The summary reports `3 to add, 0 to change, 0 to destroy`.

Apply and inspect:

```bash
terraform apply
terraform state list
```

</details>

<details>
<summary><strong>Part 3: Increase and Restore the Instance Count</strong></summary>

Temporarily change `count` from three to four and run `terraform plan`.

Confirm that Terraform proposes only `aws_s3_bucket.lab[3]` as a new instance. Restore the count to three and run another plan. Because the fourth instance was never applied, the final plan should contain no changes.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. What does `count.index` contain for the first instance?
2. Why is the account ID included in each bucket name?
3. What is the difference between the resource block and its three instances?
4. What happens to the existing addresses when count increases from three to four?
5. Why are numeric indexes potentially fragile when list elements are removed from the middle?

<details>
<summary>Review the answers</summary>

1. It starts at numeric index `0`.
2. It makes the name specific to the account and reduces the chance of a global S3 naming collision.
3. One block describes repeated behavior; state records three separately addressed instances.
4. Addresses `[0]`, `[1]`, and `[2]` remain, and Terraform adds `[3]`.
5. Numeric indexes describe position, so later elements can shift to different addresses after a middle removal.

</details>

## Cleanup

Restore `count = 3`, review the destroy plan, and run:

```bash
terraform destroy
terraform state list
```

Confirm that all three buckets are empty before destruction and absent from state afterward.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* `count` creates numerically addressed resource instances.
* `count.index` starts at zero.
* A resource using `count` is referenced by an indexed address.
* `format()` constructs a string from a format pattern and values.
* Data sources can provide account metadata without creating infrastructure.

</details>
