# Terraform State

Remote state, backends, locking, workspaces, state commands, imports, and state refactoring.

## Terraform Backend

A **backend** defines where Terraform stores its state and how Terraform performs state operations.

By default, Terraform uses the **local backend**, which stores state in a local file:
```text
terraform.tfstate
```

For real team projects, a remote backend is preferred.

### Why Use a Remote Backend?
* Keeps state out of Git
* Allows team members to share the same state
* Enables state locking, depending on backend
* Improves security when combined with encryption and access control
* Allows CI/CD systems to run Terraform against the same source of truth

### Backend Configuration Example
```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "network/dev/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Partial Backend Configuration

A backend block can intentionally omit environment-specific settings. Terraform combines the partial block with values supplied during `terraform init`.

```hcl
terraform {
  backend "s3" {
    key          = "network/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

Supply the missing bucket name in a separate file:

```hcl
# backend.hcl
bucket = "company-terraform-state"
```

Then initialize the complete backend configuration:

```bash
terraform init -backend-config=backend.hcl
```

Partial configuration is useful when the same Terraform configuration uses different backend locations in different environments or when backend settings are supplied by CI/CD. Backend blocks cannot refer to input variables, so `-backend-config` provides initialization-time values instead.

Do not put backend credentials in the backend block or a `-backend-config` file. Terraform can copy backend configuration values into the `.terraform` directory and saved plan files. Supply credentials through the backend's supported environment variables, shared credentials files, or workload identity mechanism, and do not commit environment-specific backend files unless they contain only approved non-sensitive values.

> **Exam Distinction:** `-backend-config` supplies backend settings; `-reconfigure` accepts changed backend settings without migrating state; `-migrate-state` attempts to copy existing state to the newly configured backend. These options can be combined when appropriate, for example `terraform init -backend-config=backend.hcl -migrate-state`.

After adding or changing backend configuration, run:
```bash
terraform init
```

Terraform will initialize the backend and may ask whether you want to migrate existing local state to the new backend.

When Terraform detects a backend configuration change, choose the initialization mode that matches your intent:

```bash
# Accept the new backend configuration without migrating existing state
terraform init -reconfigure

# Migrate existing state to the newly configured backend
terraform init -migrate-state
```

Use `-reconfigure` when the state is already in the correct backend or when you intentionally do not want Terraform to copy existing state. Use `-migrate-state` when changing where the current state is stored. Review and back up important state before migrating it. These options are mutually exclusive.

---
## State Locking

State locking prevents two people or systems from modifying the same Terraform state at the same time. Terraform locks state automatically when the selected backend supports locking and locking is enabled where required.

### Why Locking Matters
Imagine two engineers both run `terraform apply` against the same infrastructure:
* Engineer A creates a subnet.
* Engineer B modifies the VPC at the same time.
* Both commands try to update the same state.

Without locking, the shared state could become inconsistent or corrupted.

### What Happens During a Lock?
When Terraform starts an operation that may modify state, it tries to acquire a lock:
```text
Acquiring state lock. This may take a few moments...
```

When the operation finishes, Terraform releases the lock.

### Force Unlock
If a Terraform run crashes and leaves a stale lock, you can manually unlock it:
```bash
terraform force-unlock <LOCK_ID>
```

> **Warning:** Only force-unlock when you are sure no other Terraform operation is still running.

---

## S3 Backend

The S3 backend stores Terraform state in an AWS S3 bucket.

### Benefits
* Centralized state storage
* State can be encrypted with S3 encryption
* Access can be controlled with IAM policies
* Versioning can recover older state versions
* Useful for team collaboration and CI/CD

### Recommended S3 Bucket Settings
* Enable bucket versioning
* Enable encryption
* Block public access
* Restrict access with IAM
* Use a separate bucket for Terraform state

### Small S3 Backend Example
```hcl
terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "company-terraform-state-dev"
    key          = "checkpoint-2/network/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

The `key` is the path of the S3 object where the state will be stored.

```text
s3://company-terraform-state-dev/checkpoint-2/network/terraform.tfstate
```

`use_lockfile = true` enables the S3 backend's native state locking. Locking is not enabled automatically just because state is stored in S3. DynamoDB-based S3 locking exists for older configurations but is deprecated.

### Backend Bootstrap Note
The S3 bucket used for Terraform state usually must exist before Terraform can use it as a backend. Many teams create the backend bucket manually once, or create it in a separate bootstrap Terraform project.

---

## Terraform Workspaces (Environment Management)

While modules help you separate and reuse your *code*, **Workspaces help you separate your *state* (`terraform.tfstate`)**.

CLI workspaces let you use the same working directory and configuration with separate state instances. They are useful for temporary or parallel copies of the same infrastructure, such as feature-development environments.

They are not strong isolation boundaries for long-lived Development, QA, and Production environments because all workspaces in a configuration use the same backend and normally share its credentials and access controls.

### How do they work?

By default, you are always working in a workspace named `default`. When you create a new workspace (e.g., `dev`), Terraform creates a blank, isolated state under the hood.

* `terraform workspace new dev`: Creates a new workspace named "dev".
* `terraform workspace select prod`: Switches to the "prod" workspace.
* `terraform workspace list`: Shows all available environments.

### Where Is Workspace State Stored?

The configured backend determines where each workspace's state is stored:

| Backend and workspace | State location |
| :--- | :--- |
| Local backend, `default` workspace | `terraform.tfstate` |
| Local backend, named workspace such as `dev` | `terraform.tfstate.d/dev/terraform.tfstate` |
| Remote backend | In the backend's remote storage, using that backend's workspace naming scheme |

> **Exam Tip:** With the local backend, the `default` workspace uses `terraform.tfstate`. Named workspaces use `terraform.tfstate.d/<WORKSPACE_NAME>/terraform.tfstate`.

For the S3 backend, the `default` workspace uses the configured `key`. A named workspace uses `<workspace_key_prefix>/<WORKSPACE_NAME>/<key>`. The default `workspace_key_prefix` is `env:`, so a `dev` workspace with `key = "network/terraform.tfstate"` is stored at `env:/dev/network/terraform.tfstate`.

### The Dynamic `${terraform.workspace}` Variable

The true power of workspaces is that you can use the current environment's name directly inside your code to make dynamic decisions or name resources.

```hcl
resource "aws_s3_bucket" "app_data" {
  # If in the 'dev' workspace, the bucket is named "my-app-data-dev"
  # If in 'prod', it becomes "my-app-data-prod"
  bucket = "my-app-data-${terraform.workspace}"
}

resource "aws_instance" "server" {
  ami = "ami-123456"
  # Using a conditional: If 'prod' use t3.large, otherwise use t3.micro
  instance_type = terraform.workspace == "prod" ? "t3.large" : "t3.micro"
}
```

### Official Workspace Limitations
HashiCorp recommends workspaces for parallel instances of the same configuration. For deployments that require separate credentials and access controls, use separate root configurations and backends. Those configurations may live in separate directories or repositories and can call shared modules to avoid duplicating reusable code.

---

## Terraform State Management Commands

Terraform state commands let you inspect or modify Terraform's state through the configured backend.

> **Important:** These commands inspect or modify Terraform's record of the relationship between resource addresses and real infrastructure objects. They do not always modify the real cloud resource.

### `terraform state list`
Shows all resources currently tracked in state.

```bash
terraform state list
```

Example output:
```text
aws_vpc.main
aws_subnet.public["us-east-1a"]
aws_instance.web
```

### `terraform state show`
Shows details for one resource in state.

```bash
terraform state show aws_instance.web
```

Useful when you want to inspect the ID, tags, AMI, subnet, or other stored attributes.

### `terraform state rm`
Removes a resource from Terraform state without destroying the real cloud resource.

```bash
terraform state rm aws_instance.web
```

Real-world example:
* You created an EC2 instance with Terraform.
* Later, another team needs to manage it manually or with a different Terraform project.
* You run `terraform state rm aws_instance.web`.
* Terraform forgets the instance, but the EC2 instance still exists in AWS.

> **Warning:** After `state rm`, Terraform no longer manages that resource. If the resource block still exists in code, Terraform may plan to create a new one.

### `terraform state mv`
Moves a resource address in Terraform state.

```bash
terraform state mv aws_instance.old_name aws_instance.new_name
```

Real-world example:
* You rename a resource block from `aws_instance.old_name` to `aws_instance.new_name`.
* Without moving state, Terraform may think the old resource must be destroyed and a new one created.
* `state mv` tells Terraform this is the same real resource with a new Terraform address.

---

## State Refactoring (`moved` blocks)

If you rename a resource in your `.tf` file (e.g., changing `aws_instance.web` to `aws_instance.frontend`), Terraform will think you deleted the old one and want to create a brand new one, causing accidental deletions.

* **The Fix:** The `moved` block tells Terraform that the object changed addresses, preventing replacement caused only by the address change.
* **Workflow:** Write the `moved` block and run `terraform apply`. Retain historical `moved` blocks in reusable modules so configurations upgrading from older versions still have a valid migration path. Removing a `moved` block is a breaking change for any state that has not yet recorded the move.
```hcl
moved {
  from = aws_instance.web
  to   = aws_instance.frontend
}
```

---

## Terraform Import

`terraform import` brings an existing real-world resource under Terraform management.

Use import when:
* A resource was created manually in the cloud console
* A resource was created by another tool
* You want Terraform to start managing an existing resource instead of creating a new one

### Import Workflow
1. Write a matching resource block in Terraform code.
2. Run `terraform import`.
3. Run `terraform plan` to compare the configuration with the imported state and the remote object.
4. Reconcile any differences: adjust the `.tf` configuration when the declared desired state is wrong, or investigate the remote settings when they are unexpected.
5. Run `terraform apply` to make the approved configuration and remote object agree.
6. Run `terraform plan` again and repeat the cycle until Terraform reports no unexpected changes.

Import creates the state binding; reconciliation is the separate process of reviewing the plan, correcting the desired configuration, applying the approved changes, and confirming the result with another plan. The first plan after import may show differences such as tags or other attributes that were not represented in the initial resource block.

### Small Terraform Import Example
Suppose an S3 bucket already exists in AWS:
```text
my-existing-company-bucket
```

First, write the Terraform resource block:
```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "my-existing-company-bucket"
}
```

Then import the real bucket into Terraform state:
```bash
terraform import aws_s3_bucket.logs my-existing-company-bucket
```

Now check the plan:
```bash
terraform plan
```

If Terraform wants to change many things, update the `.tf` code until it matches the real bucket configuration.

### Import Block Example
Modern Terraform also supports import blocks, which let you declare imports in code:
```hcl
import {
  to = aws_s3_bucket.logs
  id = "my-existing-company-bucket"
}

resource "aws_s3_bucket" "logs" {
  bucket = "my-existing-company-bucket"
}
```

Then run:
```bash
terraform plan
terraform apply
terraform plan
```

Review the first plan before applying. It should show the import and any intended configuration reconciliation. The apply performs those approved changes and records the resulting state. The second plan verifies that reconciliation is complete and reports no unexpected changes.

For example, after the first apply you might add a tag to the resource configuration:

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "my-existing-company-bucket"

  tags = {
    ManagedBy = "Terraform"
  }
}
```

Because the existing bucket does not have that tag yet, run the reconciliation cycle again:

```bash
terraform plan    # review the tag change
terraform apply   # add the tag to the existing bucket
terraform plan    # confirm no unexpected changes remain
```

---

## Removed Blocks

A `removed` block records that Terraform should stop managing a resource. Unlike deleting a resource block by itself, it lets you explicitly choose whether Terraform destroys the real infrastructure or only removes the resource from state.

To keep the real infrastructure, set `destroy = false`. This is a code-reviewed alternative to running:
```bash
terraform state rm <resource_address>
```

### Example
Suppose Terraform currently manages this resource:
```hcl
resource "aws_s3_bucket" "old_logs" {
  bucket = "company-old-logs"
}
```

You want Terraform to stop managing the bucket, but you do **not** want to delete the real bucket in AWS.

Remove the resource block from your code and add:
```hcl
removed {
  from = aws_s3_bucket.old_logs

  lifecycle {
    destroy = false
  }
}
```

Then run:
```bash
terraform plan
terraform apply
```

Terraform removes `aws_s3_bucket.old_logs` from state, but leaves the real S3 bucket running in AWS.

The `lifecycle` block is required for a `removed` block and makes the removal behavior explicit. If `destroy` is `true`—which is the default behavior—Terraform plans to destroy the real resource before removing it from state. Use `destroy = false` only when the real object must continue to exist, and always inspect `terraform plan` carefully.

After the removal is applied:

* Terraform no longer tracks or updates the resource.
* The old resource address can no longer be referenced elsewhere in the configuration.
* If `destroy = false`, you become responsible for managing or importing the real resource elsewhere.

### `removed` Block vs `terraform state rm`
| Method | Stored in Code? | Reviewable in Git? | Default Result |
| :--- | :---: | :---: | :--- |
| `terraform state rm` | No | No | Forgets the resource without destroying it |
| `removed` with `destroy = false` | Yes | Yes | Forgets the resource without destroying it |
| `removed` with `destroy = true` | Yes | Yes | Destroys the resource and removes it from state |

> **Best Practice:** Use a `removed` block when the change should be visible in code review and repeatable across team environments.

---

## Cross-Project Collaboration Using Remote State Data Source

Sometimes one Terraform project needs values created by another Terraform project.

Example:
* Project A creates the network: VPC, subnets, route tables.
* Project B creates the application servers.
* Project B needs the VPC ID and subnet IDs from Project A.

Terraform can read outputs from another project's remote state using the `terraform_remote_state` data source.

### Network Project Output
```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}
```

### Application Project Reads Network State
```hcl
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "company-terraform-state-dev"
    key    = "network/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "app" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  subnet_id     = data.terraform_remote_state.network.outputs.public_subnet_ids[0]

  tags = {
    Name = "app-server"
  }
}
```

> **Important:** The data source exposes only root-module outputs to Terraform expressions, but the credentials used to retrieve those outputs must normally be able to read the entire state snapshot. That snapshot can contain sensitive data that was never declared as an output.

Prefer publishing shared information through provider-specific resources, such as DNS records, parameter stores, or configuration stores, when practical. For HCP Terraform or Terraform Enterprise, prefer the `tfe_outputs` data source when only workspace outputs are required because it does not require full state access.

---
