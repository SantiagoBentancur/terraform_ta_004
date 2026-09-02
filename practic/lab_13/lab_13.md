# Lab 13: Import, Refactor, and Remove State

## Objective

An S3 bucket was created manually and now needs to be managed through Terraform. Later, the team wants to rename its Terraform address, and eventually transfer responsibility for the bucket without deleting the remote object.

In this lab, you will follow that complete ownership lifecycle: import the existing bucket, reconcile its configuration, refactor its Terraform address, and deliberately remove its state binding while leaving the bucket intact.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Not started. Complete the requirements below before adding your solution.

**[View my Terraform solution](./lab_13.tf)**

When completed, this implementation should:

* Adopt an existing S3 bucket without recreating it.
* Reconcile configuration and remote attributes after import.
* Rename the Terraform address while preserving the object binding.
* Remove that binding declaratively without deleting the bucket.

Validation commands:

```bash
terraform fmt -check
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Distinguishing configuration, state, and remote objects
* Importing existing infrastructure
* Reconciling configuration after import
* Refactoring with a `moved` block
* Removing management with a `removed` block
* Comparing declarative removal with `terraform state rm`

## Prerequisites

* Review [Terraform Import](../../README.md#terraform-import), [State Refactoring](../../README.md#state-refactoring-moved-blocks), and [Removed Blocks](../../README.md#removed-blocks).
* Use Terraform 1.7 or later.
* Configure the AWS CLI and Terraform AWS credentials with S3 permissions.

> **Cleanup Warning:** This lab creates an S3 bucket outside Terraform and eventually leaves it unmanaged. Complete the manual deletion step.

## Step-by-Step Requirements

Build the configuration in `lab_13.tf` as the steps request. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Create an Object Outside Terraform</strong></summary>

<details>
<summary>Configuration, state, and remote object overview</summary>

This lab deliberately starts with three separate ideas:

* **Configuration** describes the desired object at a Terraform address.
* **State** binds that address to a real remote object's identity and stores provider-reported attributes.
* **The remote object** exists in AWS independently of whether Terraform currently knows about it.

Writing a resource block creates configuration, not a state binding. Import connects an existing remote identity to the selected Terraform resource address.

</details>

Choose a globally unique lowercase bucket name:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="terraform-associate-lab13-${ACCOUNT_ID}"
aws s3api create-bucket --bucket "$BUCKET_NAME" --region us-east-1
```

The AWS CLI creates the remote object, but Terraform has no configuration or state binding for it yet.

Confirm its existence with `aws s3api head-bucket`, and confirm that `terraform state list` does not yet contain it.

</details>

<details>
<summary><strong>Part 2: Write the Destination Configuration</strong></summary>

1. Require Terraform 1.7 or later and the AWS provider.
2. Configure the AWS provider for `us-east-1`.
3. Declare the required string variable `bucket_name`.
4. Declare `aws_s3_bucket.imported` with:
   * `bucket = var.bucket_name`
   * `Purpose` and `ManagedBy` tags
5. Output the managed bucket name.

Run:

```bash
terraform init
terraform fmt
terraform validate
terraform plan -var="bucket_name=$BUCKET_NAME"
```

Terraform should propose creating the bucket because configuration alone does not bind the existing object to state. Do not apply this plan.

This is the critical observation for Part 2: matching names do not cause Terraform to adopt infrastructure automatically.

</details>

<details>
<summary><strong>Part 3: Import and Reconcile the Bucket</strong></summary>

Run:

```bash
terraform import -var="bucket_name=$BUCKET_NAME" aws_s3_bucket.imported "$BUCKET_NAME"
terraform state list
terraform state show aws_s3_bucket.imported
```

CLI import creates the state binding but does not generate a complete desired configuration.

Reconcile the imported object:

```bash
terraform plan -var="bucket_name=$BUCKET_NAME"
terraform apply -var="bucket_name=$BUCKET_NAME"
```

The first plan may add the configured tags.

Before applying the reconciliation plan, confirm that it does not propose replacing or creating the already imported bucket. After applying, run another normal plan and expect no changes.

</details>

<details>
<summary><strong>Part 4: Rename the Terraform Address</strong></summary>

Rename the resource from `imported` to `archive`, update references, and add:

```hcl
moved {
  from = aws_s3_bucket.imported
  to   = aws_s3_bucket.archive
}
```

Run:

```bash
terraform plan -var="bucket_name=$BUCKET_NAME"
terraform apply -var="bucket_name=$BUCKET_NAME"
terraform state list
```

The state address should change without replacing the bucket solely because of the rename. Keep the `moved` block as migration history.

Confirm that:

* The plan describes an address move.
* The bucket name and remote identity remain unchanged.
* State contains `aws_s3_bucket.archive` and no longer contains `aws_s3_bucket.imported`.

</details>

<details>
<summary><strong>Part 5: Stop Managing Without Destroying</strong></summary>

Remove the resource and its output, retain the historical `moved` block, and add:

```hcl
removed {
  from = aws_s3_bucket.archive

  lifecycle {
    destroy = false
  }
}
```

Run:

```bash
terraform plan -var="bucket_name=$BUCKET_NAME"
terraform apply -var="bucket_name=$BUCKET_NAME"
terraform state list
```

The plan should remove the state binding without deleting the bucket.

After applying, verify both sides separately:

```bash
terraform state list
aws s3api head-bucket --bucket "$BUCKET_NAME"
```

Terraform should no longer list the resource, while AWS should still report that the bucket exists.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. Does writing a resource block automatically adopt an existing object with the same name?
2. What does import add: configuration, a state binding, or a new remote object?
3. Why must you run a plan after importing?
4. Why does a `moved` block preserve the bucket during an address rename?
5. What is the difference between `removed { destroy = false }` and deleting the resource block alone?
6. Why can a `removed` block be preferable to a one-time `terraform state rm` command for a planned handoff?

<details>
<summary>Review the design questions and answers</summary>

1. No. Terraform needs an explicit import to bind the existing identity to the resource address.
2. Import creates a state binding. The destination configuration must already exist for CLI import, and the remote object is not recreated.
3. Import does not guarantee that the written desired configuration matches all remote settings.
4. It declares that the old and new addresses identify the same managed object.
5. Removing only the resource block normally proposes destroying the managed object; `destroy = false` explicitly removes management while preserving it.
6. The declarative handoff can be reviewed, versioned, and applied consistently by collaborators.

The lab is complete only when you can verify configuration, state, and AWS independently instead of treating them as one thing.

</details>

## Cleanup

After confirming the bucket is absent from state, delete the unmanaged empty bucket:

```bash
aws s3api delete-bucket --bucket "$BUCKET_NAME" --region us-east-1
aws s3api head-bucket --bucket "$BUCKET_NAME"
```

The final command should report that the bucket is unavailable.

Do not delete the bucket until you have confirmed it is absent from Terraform state; otherwise, Terraform and the manual cleanup operation could still compete over ownership.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* Import binds one existing object to one Terraform resource address.
* CLI import requires a destination resource block.
* `moved` changes an address while preserving the remote binding.
* `removed` with `destroy = false` forgets an object without destroying it.
* If a forgotten object's resource block remains, Terraform may plan to create another object.

</details>
