# Lab 9: Lifecycle Guardrails and CLI Operations

## Objective

Your team manages two production S3 buckets: a critical archive that must be protected from accidental deletion and an application-logs bucket with one operational tag maintained outside Terraform. Every infrastructure change must be reviewed before it is applied, and later refactoring must preserve the existing remote objects.

In this lab, you will operate these buckets through a production-style workflow. You will save and inspect an execution plan, examine state, test lifecycle rules, rename a Terraform resource address safely, request an intentional replacement, and inspect the dependency graph that connects the resources.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Completed.

**[View my Terraform solution](./lab_9.tf)**

When completed, this implementation should:

* Apply an inspected, saved execution plan.
* Protect selected infrastructure with lifecycle rules.
* Preserve a remote object while renaming its Terraform address.
* Demonstrate replacement planning and dependency-graph generation.

Validation commands:

```bash
terraform fmt -check
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Saving, inspecting, and applying execution plans
* Using `prevent_destroy` and targeted `ignore_changes`
* Creating an explicit dependency with `depends_on`
* Renaming a resource with a `moved` block
* Inspecting Terraform state
* Requesting replacement with `-replace`
* Generating a graph with `terraform graph`

## Prerequisites

* Review [The `lifecycle` Meta-Argument](../../README.md#the-lifecycle-meta-argument), [Saving and Inspecting Execution Plans](../../README.md#saving-and-inspecting-execution-plans), and [State Refactoring](../../README.md#state-refactoring-moved-blocks).
* Configure AWS credentials with permission to create and delete S3 buckets.

> **Cleanup Warning:** The protected bucket cannot be destroyed until you remove its `prevent_destroy` rule.

## Step-by-Step Requirements

Build the configuration in `lab_9.tf` in the order shown below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Build, Review, and Apply a Saved Plan</strong></summary>

<details>
<summary>Production change workflow</summary>

The team requires the proposed actions to be reviewed before execution. A saved plan separates those stages: `terraform plan -out=...` writes the proposed actions to a binary artifact, `terraform show` displays it, and `terraform apply PLANFILE` executes that reviewed artifact without generating a new plan.

Lifecycle rules change how Terraform handles a managed resource:

* `prevent_destroy` rejects a plan that would destroy the protected instance.
* `ignore_changes` tells Terraform not to reconcile selected remote changes after creation.

These rules affect Terraform's planning behavior. They are not AWS-side deletion protection or access controls.

</details>

1. Configure the AWS provider to use `us-east-1`.
2. Read the current account ID with `aws_caller_identity`.
3. Create `aws_s3_bucket.critical_archive`.
   * Set its bucket name to `terraform-associate-lab9-archive-<account-id>`, replacing `<account-id>` with the value read from `aws_caller_identity`.
   * Add `prevent_destroy = true`.
4. Create `aws_s3_bucket.application_logs`.
   * Set its bucket name to `terraform-associate-lab9-logs-<account-id>`, using the same account ID.
   * Add an explicit dependency on the archive bucket.
   * Add `Name`, `Environment`, `OperationsNote`, and `ManagedBy` tags.
   * Ignore only `tags["OperationsNote"]`.
5. Output both bucket names.

Run:

```bash
terraform init
terraform fmt
terraform validate
terraform plan -out=production.plan
terraform show production.plan
terraform apply production.plan
```

The saved plan is binary, can contain sensitive data, can become stale, and is not a state lock. Do not commit it.

Before applying, confirm:

* The plan proposes exactly two S3 buckets.
* Both names include the current AWS account ID.
* The logs bucket depends on the archive bucket.
* The plan summary reports `2 to add, 0 to change, 0 to destroy`.

After applying, run `terraform plan` again and expect no changes.

</details>

<details>
<summary><strong>Part 2: Inspect Terraform State</strong></summary>

Run:

```bash
terraform state list
terraform state show aws_s3_bucket.application_logs
```

Confirm that the state contains both resource addresses and provider-reported attributes.

Also confirm that `terraform state show` reads Terraform state; it does not print the HCL resource block from `lab_9.tf`.

</details>

<details>
<summary><strong>Part 3: Test Targeted ignore_changes</strong></summary>

In AWS, change only the `OperationsNote` tag on the application-logs bucket. Then run:

```bash
terraform plan
```

Terraform should ignore that selected map element while continuing to manage the other configured tags. Changing `Environment` outside Terraform should produce a plan that restores its configured value.

Restore the externally changed `Environment` tag through a reviewed Terraform apply before continuing.

</details>

<details>
<summary><strong>Part 4: Test prevent_destroy</strong></summary>

Run:

```bash
terraform plan -destroy
```

Terraform should reject the plan because `aws_s3_bucket.critical_archive` has `prevent_destroy = true`. This protects against Terraform-planned destruction while the rule remains in configuration; it does not create an AWS-side deletion lock.

Confirm that no bucket is deleted merely by running the failed destroy plan.

</details>

<details>
<summary><strong>Part 5: Rename a Resource with a moved Block</strong></summary>

Rename `aws_s3_bucket.application_logs` to `aws_s3_bucket.service_logs`, update its references, and add:

```hcl
moved {
  from = aws_s3_bucket.application_logs
  to   = aws_s3_bucket.service_logs
}
```

Run:

```bash
terraform plan
terraform apply
terraform state list
```

Terraform should record the new address without replacing the bucket solely because of the rename. Retain the `moved` block as migration history.

Review the plan before applying and confirm it reports the move rather than one bucket destroy and another bucket creation.

</details>

<details>
<summary><strong>Part 6: Request Replacement and Generate a Graph</strong></summary>

Request replacement in a plan:

```bash
terraform plan -replace=aws_s3_bucket.service_logs
```

Do not apply it unless the bucket is empty and you intentionally want to recreate it.

Generate DOT graph data:

```bash
terraform graph > architecture.dot
```

If Graphviz is installed:

```bash
dot -Tsvg architecture.dot > architecture.svg
```

Inspect `architecture.dot` and identify the dependency edge created by `depends_on`. Remember that `terraform graph` emits DOT text; Graphviz performs the optional image conversion.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. Why can applying a saved plan be safer than running a new interactive apply after review?
2. Does `prevent_destroy` protect a bucket from deletion through the AWS console or CLI?
3. Why is ignoring only `tags["OperationsNote"]` safer than ignoring the complete `tags` map?
4. Why does a `moved` block avoid recreating the bucket during an address rename?
5. What is the difference between `-replace` and `-target`?
6. Does generating a Terraform graph change infrastructure?

<details>
<summary>Review the design questions and answers</summary>

1. It executes the exact reviewed artifact rather than creating a potentially different plan at apply time. The artifact can still become stale, so Terraform checks it before execution.
2. No. It blocks Terraform plans while the lifecycle rule remains in configuration; it is not an AWS-side control.
3. Targeted ignoring preserves Terraform management of every other tag and exposes unrelated drift.
4. It tells Terraform that the old and new addresses represent the same managed object.
5. `-replace` requests recreation of a particular managed instance. `-target` creates a partial plan focused on selected addresses and dependencies and is intended for exceptional situations.
6. No. It reads the configuration and emits a DOT representation of the dependency graph.

The purpose of this lab is to practice controlling Terraform operations without confusing planning safeguards with cloud-provider protections.

</details>

## Cleanup

Remove `prevent_destroy`, keep the `moved` block and current resource name, then run:

```bash
terraform plan -destroy
terraform destroy
```

After confirming both buckets are gone, remove local plan and graph artifacts that exist.

Run `terraform state list` and confirm that neither bucket remains in state.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* Applying a saved plan uses the reviewed plan instead of generating a new one.
* `ignore_changes` can target one map element.
* `prevent_destroy` works only while its lifecycle rule remains configured.
* A `moved` block changes Terraform's address without changing the remote identity.
* `-replace` supersedes the older `terraform taint` workflow.
* `terraform graph` emits DOT data, not an image.

</details>
