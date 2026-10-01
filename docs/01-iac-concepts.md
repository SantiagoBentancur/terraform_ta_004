# IaC Concepts

This chapter introduces the ideas behind Infrastructure as Code and Terraform's desired-state model.

## What Infrastructure as Code Means

**Infrastructure as Code (IaC)** means describing and managing infrastructure with version-controlled, human-readable configuration instead of relying on a sequence of manual console actions or undocumented commands. The configuration can describe resources such as networks, servers, databases, permissions, and DNS records.

IaC is useful because the configuration can be:

* **Repeatable:** the same definition can be used to create consistent environments.
* **Reviewable:** infrastructure changes can be inspected in a diff before they are applied.
* **Auditable:** version history shows what changed, when, and why.
* **Automatable:** standard workflows can validate, plan, and apply changes without repeating manual steps.

Terraform is one IaC tool. It uses a **declarative** model: you describe the desired result, and Terraform calculates the operations required to reconcile that desired result with the infrastructure that exists.

## How Terraform Works: A First Run

Terraform uses `.tf` configuration files to describe the result you want rather than requiring you to write every API operation. It then determines which actions are necessary to make the managed objects match the configuration.

The initial workflow is:

```text
Write configuration → terraform init → terraform plan → terraform apply
     desired state        prepare          preview            execute
```

After initialization, the everyday cycle is usually:

```text
Edit configuration → terraform plan → terraform apply
```

Run `terraform init` again when initialization is required, such as after changing provider requirements, module sources, or backend configuration.

### A Small Local Example

The following configuration uses the `hashicorp/local` provider to create a text file. It runs entirely on your computer, so it does not require a cloud account or credentials.

Create a `.tf` file containing:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "hello" {
  filename = "hello.txt"
  content  = "Hello from Terraform!"
}
```

This configuration declares the **desired state**: a file named `hello.txt` with specific content. It does not contain procedural instructions such as “open a file, write a line, and close it.”

### Prepare the Working Directory

```bash
terraform init
```

Terraform reads the provider requirement and installs `hashicorp/local`. It also creates or updates:

* **`.terraform/`**: Local working data, including installed providers and modules. Do not commit this directory.
* **`.terraform.lock.hcl`**: The exact provider selection and checksums used to verify the downloaded package. Normally commit this file.

Initialization prepares Terraform, but it does not create `hello.txt`.

### Preview the Proposed Changes

```bash
terraform plan
```

Terraform reads the configuration, examines the available state and managed objects, and calculates the actions required to reach the desired state. The first plan should report that one `local_file` resource will be added.

A plan is a preview. A normal `terraform plan` does not execute the proposed resource changes.

### Apply the Changes

```bash
terraform apply
```

When executed without a saved plan, `terraform apply` creates a new plan, asks for approval, and then asks the provider to perform the approved operations. In this example, the local provider creates `hello.txt`. When using the default local backend, Terraform also creates or updates `terraform.tfstate` to associate `local_file.hello` with the file it now manages.

Now change the desired content:

```hcl
content = "Terraform updated this file!"
```

The next `terraform plan` detects the difference and proposes the required change. After approval, `terraform apply` performs it and records the resulting state. This is the central Terraform workflow: declare the desired result, review Terraform's proposed reconciliation, and apply it.

### Clean Up the Example

When you finish the exercise, preview and remove the object managed by this configuration:

```bash
terraform destroy
```

`terraform destroy` creates a destruction plan and asks for approval. After approval, the local provider deletes `hello.txt`, and Terraform records in state that the resource is no longer managed.

The following sections explain each part of this workflow in more detail, beginning with the core commands and then the providers, lock file, configuration, and state that make the workflow possible.

---


## Resource Blocks and References

A **resource** is a primary building block in Terraform. It represents a managed object whose lifecycle Terraform can create, update, track, or destroy. This may be physical infrastructure, such as an EC2 instance, or a logical object, such as an IAM policy, DNS record, GitHub repository, or `terraform_data` resource.

Examples:

* An AWS EC2 instance
* An AWS VPC
* An S3 bucket
* A security group
* An IAM user
* A DNS record
* A built-in `terraform_data` resource

### Resource Block Anatomy

```hcl
resource "aws_s3_bucket" "web" {
  bucket_prefix = "web-server-"

  tags = {
    Name = "web-server"
  }
}
```

In this example:
* **`resource`**: Tells Terraform you are declaring infrastructure to manage.
* **`aws_s3_bucket`**: The resource type. It comes from the AWS provider and tells Terraform what kind of object to create.
* **`web`**: The local name used to distinguish this block from other resources of the same type.
* **`aws_s3_bucket.web`**: The resource address used to identify and reference it in the Terraform configuration.
* **Arguments:** Values you configure inside the block, such as `bucket_prefix` and `tags`.

The general resource-address syntax is:

```text
<RESOURCE_TYPE>.<LOCAL_NAME>
```

### Arguments vs. Attributes

* **Arguments** are values you provide to Terraform as input for a resource.
  * Example: `bucket_prefix = "web-server-"`
* **Attributes** are values Terraform can read from a resource, often after the resource is created.
  * Example: `aws_s3_bucket.web.arn`

Some values are both configurable arguments and readable attributes, depending on the resource type. Provider documentation tells you which fields are supported.

### Resource Attribute References

You can reference the attribute of one resource and use it in another resource.

* **Syntax:** `<RESOURCE_TYPE>.<LOCAL_NAME>.<ATTRIBUTE>`

```hcl
resource "terraform_data" "source" {
  input = "original-value"
}

resource "terraform_data" "copy" {
  input = terraform_data.source.output
}
```

Here, `terraform_data.source.output` means:
* `terraform_data`: Resource type
* `source`: Local resource name
* `output`: Attribute exported by that resource

Terraform also uses references to infer dependencies. Because `terraform_data.copy` reads an attribute from `terraform_data.source`, Terraform handles `source` before `copy`.

---

## Configuration, State, and Remote Objects

Terraform uses a **declarative** approach: you describe the desired result instead of writing a sequence of API instructions.

* **Configuration:** Describes the desired infrastructure and behavior in `.tf` files.
* **Terraform State:** Maps resource addresses to real objects and stores metadata and known attributes. Terraform requires this mapping to know, for example, which EC2 instance belongs to `aws_instance.web`. State is Terraform's record—it is not the infrastructure itself.
* **Remote Objects:** The infrastructure that actually exists in a provider system such as AWS.

During `terraform plan`, Terraform normally asks providers to refresh information about managed objects and compares the real objects, prior state, and current configuration. It then proposes whether each object should be created, updated, replaced, destroyed, or left unchanged.

### Reading Terraform Plan Symbols

The symbol beside each object in a plan summarizes the proposed action:

| Symbol | Proposed Action |
| :---: | :--- |
| `+` | Create the object |
| `-` | Destroy the object |
| `~` | Update the object in place |
| `-/+` | Replace the object by destroying it first and then creating its replacement |
| `+/-` | Replace the object by creating its replacement first and then destroying the old object, typically because `create_before_destroy` applies |
| `<=` | Read a data source during the apply operation |

Within an object's attribute changes:

* `old -> new` shows the value changing from the value on the left to the value on the right.
* `# forces replacement` identifies an attribute change that prevents an in-place update and requires the object to be recreated.
* `(known after apply)` means Terraform cannot determine the final value until it performs the operation. This is not an error by itself.

> **Before Applying a Replacement:** Confirm that every replacement is intentional and inspect the attributes marked `# forces replacement`. Evaluate downtime, dependency, naming, quota, and persistent-data consequences; create or verify backups when applicable. For important changes, save the reviewed plan with `terraform plan -out=<filename>.plan` and apply that exact artifact with `terraform apply <filename>.plan`.

During `terraform apply`, providers translate the approved actions into API operations. As operations complete, Terraform records the results in state. If someone changes a managed object outside Terraform, a later plan can detect this **drift** and propose how to reconcile it with the configuration.

---
