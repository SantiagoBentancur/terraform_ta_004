# Lab 14: Remote S3 State, Locking, and Workspaces

## Objective

Your team has a Terraform workload whose state exists only on one operator's machine. Before the configuration can be used collaboratively, the state must move to protected remote storage with locking, but the backend bucket must already exist before Terraform can use it.

In this lab, you will bootstrap that S3 bucket separately, create a workload with local state, and migrate the state through a partially configured backend. You will then enable native S3 lockfiles and compare how the default and named CLI workspaces use different remote state paths.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Not started. Complete the requirements below before adding your solution.

* [Bootstrap configuration](./bootstrap/main.tf)
* [Workload configuration](./workload/main.tf)
* [Backend configuration example](./workload/backend.hcl.example)

When completed, this implementation should:

* Bootstrap protected storage separately from the configuration that consumes it.
* Migrate existing local state through partial backend configuration.
* Enable native S3 lockfiles.
* Demonstrate that CLI workspaces create separate state instances and keys.

Validation commands must be run from the relevant directory:

```bash
terraform fmt -check
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Separating backend bootstrap from workload configuration
* Supplying partial backend configuration
* Comparing `-reconfigure` and `-migrate-state`
* Enabling S3 native locking with `use_lockfile`
* Creating and selecting CLI workspaces
* Cleaning up a remote backend safely

## Prerequisites

* Review [Terraform Backend](../../README.md#terraform-backend), [State Locking](../../README.md#state-locking), [S3 Backend](../../README.md#s3-backend), and [Terraform Workspaces](../../README.md#terraform-workspaces-environment-management).
* Configure AWS credentials with permission to manage an S3 bucket and its objects.

> **Safety Warning:** Terraform state can contain sensitive data. The state bucket must never be public.

## Project Structure

```text
lab_14/
├── .gitignore
├── lab_14.md
├── bootstrap/
│   └── main.tf
└── workload/
    ├── main.tf
    └── backend.hcl.example
```

## Step-by-Step Requirements

Build the bootstrap and workload configurations in the order shown below. Do not open or copy another solution first. Keep their working directories and state separate throughout the lab.

<details>
<summary><strong>Part 1: Bootstrap the State Bucket</strong></summary>

<details>
<summary>Why bootstrap separately?</summary>

A backend must exist before `terraform init` can use it. Therefore, the temporary bootstrap configuration uses local state to create storage for the separate workload configuration.

</details>

1. In `bootstrap/main.tf`:
   * Configure AWS for `us-east-1`.
   * Read the account ID.
   * Create a globally distinctive S3 bucket with `force_destroy = true` for this disposable lab.
   * Enable versioning and server-side encryption.
   * Block all public access.
   * Output the bucket name.

Run from `bootstrap/`:

```bash
terraform init
terraform fmt
terraform validate
terraform apply
terraform output -raw state_bucket_name
```

Save the output value.

Before continuing, confirm:

* Versioning is enabled.
* Server-side encryption is configured.
* Every public-access-block setting is enabled.
* The bucket name is globally distinctive.
* The bootstrap state remains local and separate from the workload.

</details>

<details>
<summary><strong>Part 2: Create Workload State Locally</strong></summary>

2. In `workload/main.tf`, initially omit any backend block.
3. Require Terraform 1.10 or later.
4. Create `terraform_data.workspace_record` containing `terraform.workspace`.
5. Output the current workspace and stored record.

Run from `workload/`:

```bash
terraform init
terraform fmt
terraform validate
terraform apply
terraform state list
```

At this point, the default local backend stores the workload state on disk.

Confirm that `terraform state list` contains `terraform_data.workspace_record` and that the workload directory contains its own local state before migrating it.

</details>

<details>
<summary><strong>Part 3: Add the Partial Backend and Migrate State</strong></summary>

6. Add a partial S3 backend block containing:
   * `key = "labs/lab14/terraform.tfstate"`
   * `region = "us-east-1"`
   * `encrypt = true`
   * `use_lockfile = true`
   * Do not put the bucket or credentials in this block.
7. Copy the backend example:

```bash
cp backend.hcl.example backend.hcl
```

8. Replace its placeholder so the ignored file contains:

```hcl
bucket = "YOUR_STATE_BUCKET_NAME"
```

Migrate the existing local state:

```bash
terraform init -migrate-state -backend-config=backend.hcl
terraform state list
terraform plan
```

`-migrate-state` copies existing state to the newly configured backend. By contrast, `-reconfigure` accepts the new backend settings without attempting to migrate existing state.

The default workspace state key is:

```text
labs/lab14/terraform.tfstate
```

After migration, confirm:

* `terraform state list` still contains the workload record.
* A normal plan proposes no recreation.
* The S3 bucket contains the expected default-workspace state object.
* `backend.hcl` is ignored and contains no credentials.

</details>

<details>
<summary><strong>Part 4: Create and Compare a Named Workspace</strong></summary>

Run:

```bash
terraform workspace new dev
terraform workspace list
terraform plan
terraform apply
terraform output current_workspace
```

The named workspace has separate state. With the default S3 workspace prefix, its key is:

```text
env:/dev/labs/lab14/terraform.tfstate
```

Switch and compare:

```bash
terraform workspace select default
terraform output current_workspace
terraform workspace select dev
terraform output current_workspace
```

Optionally list the bucket keys with the AWS CLI.

Confirm that applying in `dev` creates a separate record rather than modifying the default workspace record. Switching workspaces should change both `terraform.workspace` and the selected state.

</details>

<details>
<summary><strong>Part 5: Understand State Locking</strong></summary>

S3 native locking uses a neighboring `.tflock` object while an operation owns the lock. A competing write to the same workspace state should fail to acquire it.

Do not use `-lock=false` normally. Use `terraform force-unlock` only after confirming that no valid operation still owns the lock.

Do not manufacture a stale lock or force-unlock this lab merely for demonstration. Understanding ownership and safe recovery is the learning goal.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. Why must the backend bucket be created outside the workload configuration that will use it?
2. Can a backend block use input variables or resource references?
3. What is the difference between `terraform init -migrate-state` and `-reconfigure`?
4. Do CLI workspaces provide separate credentials or security boundaries?
5. Where is the default workspace state stored compared with the `dev` state?
6. Why should `force-unlock` be used only after verifying that the lock has no active owner?

<details>
<summary>Review the design questions and answers</summary>

1. Terraform must initialize the backend before it can plan resources, so the storage must already exist or be bootstrapped separately.
2. No. Backend initialization occurs before normal input and resource expression evaluation.
3. `-migrate-state` attempts to copy existing state to the new backend; `-reconfigure` accepts new backend settings without migrating the existing state.
4. No. They separate state instances but share configuration, backend credentials, and surrounding access controls.
5. The default uses the configured `key`; a named workspace uses `<workspace_key_prefix>/<workspace>/<key>`.
6. Unlocking an actively owned state can permit concurrent writers and corrupt or overwrite state.

The purpose of the lab is to follow state ownership and location through each transition, not merely to make `terraform init` succeed.

</details>

## Cleanup

Destroy every workspace before deleting the backend:

```bash
terraform workspace select dev
terraform destroy
terraform workspace select default
terraform workspace delete dev
terraform destroy
```

Then return to `bootstrap/` and run:

```bash
terraform destroy
```

`force_destroy = true` allows removal of remaining disposable lab state versions and lock artifacts. Evaluate that setting carefully for production buckets.

Finally, confirm that both workload states are destroyed, the named workspace is removed, and the bootstrap bucket no longer exists.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* The default backend is local.
* Backend changes require `terraform init`.
* Partial configuration supplies omitted backend arguments during initialization.
* S3 native locking uses `use_lockfile = true`.
* Named workspaces use `<workspace_key_prefix>/<workspace>/<key>`.
* Backend infrastructure usually requires a separate bootstrap process.

</details>
