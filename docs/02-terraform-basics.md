# Terraform Basics

Providers, configuration blocks, types, variables, outputs, and project structure.

## Providers

A provider is a plugin that lets Terraform interact with an external API.

### Terraform Registry and Provider Source Addresses

The public [Terraform Registry provider directory](https://registry.terraform.io/browse/providers) is the main catalog for publicly available providers and their versioned documentation. A provider source address identifies where Terraform should obtain a provider and has this format:

```text
[hostname/]namespace/type
```

For example, `hashicorp/aws` is shorthand for the complete source address `registry.terraform.io/hashicorp/aws`:

| Address part | Example | Purpose |
| :--- | :--- | :--- |
| **Hostname** | `registry.terraform.io` | Registry that distributes the provider. Terraform assumes the public Registry when this part is omitted. |
| **Namespace** | `hashicorp` | Organization or publisher responsible for the provider. |
| **Type** | `aws` | Provider's name; it normally also becomes the local name used by the module. |

Organizations are not limited to the public Registry. A source such as `terraform.example.com/examplecorp/ourcloud` can refer to a provider in a private or internal registry. Terraform can also be configured to install providers through filesystem or network mirrors. See HashiCorp's [provider requirements](https://developer.hashicorp.com/terraform/language/providers/requirements) and [provider installation](https://developer.hashicorp.com/terraform/cli/config/config-file#provider-installation) documentation.

During `terraform init`, Terraform reads the provider requirements from the configuration, considers the selected versions in `.terraform.lock.hcl`, and installs the required provider plugins from the configured registry, mirror, or cache. The version displayed on a Registry documentation page is not necessarily the version installed in a project; the configuration's version constraints and the dependency lock file control that selection.

> **Exam Tip — Provider Installation Path:** For a normally initialized working directory, Terraform stores installed provider packages under `.terraform/providers`, organized by source address, version, and target platform. An AWS provider path looks similar to `.terraform/providers/registry.terraform.io/hashicorp/aws/<VERSION>/<OS_ARCH>/`. Terraform manages this directory automatically; do not edit or commit it. A configured shared plugin cache or a custom Terraform data directory can change where the underlying files are stored.

![Annotated anatomy of an AWS provider page in the Terraform Registry](assets/terraform-registry-provider-anatomy.png)

### Declaring and Configuring a Provider

Provider **requirements** and provider **configurations** have different purposes:

* **`required_providers`** declares the provider's local name, source address, and acceptable versions.
* **`provider`** configures an instance of that provider with settings such as a region, endpoint, or authentication behavior.

An explicit `required_providers` declaration is the recommended practice for every external provider, but Terraform can sometimes operate without one. If Terraform encounters the local provider name `aws` without an explicit source address, it uses the implied address `registry.terraform.io/hashicorp/aws`. This inference exists for backward compatibility and should not be relied on in modern configurations: it assumes the `hashicorp` namespace, cannot identify a community or private provider, and does not document an intentional version constraint.

The `provider` block is also not always required. Terraform can use an implied empty default configuration when a provider needs no explicit settings or can obtain them from external sources. In the following AWS example, the block is present because it explicitly sets the region:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket_prefix = "provider-example-"
}
```

In this example, `required_providers` explicitly tells Terraform to install `hashicorp/aws` at a version allowed by `~> 6.0`, while `provider "aws"` configures its AWS region. The `aws_` prefix in `aws_s3_bucket` associates that resource type with the local provider name `aws`.

### Provider Tiers

| Type | Description |
| :--- | :--- |
| **Official** | Owned and maintained by HashiCorp. |
| **Partner / Partner Premier** | Written and maintained by a third-party technology partner and approved through HashiCorp's partner program. |
| **Community** | Owned and maintained by individual contributors. |
| **Archived** | An Official or Partner provider that is no longer maintained. |

The syntax and other uses of `required_providers` are covered in [Terraform Settings Block](#terraform-settings-block-terraform-).

### AWS Provider Source Credentials

When authenticating the AWS provider, you have several options:

* **Environment Variables (Recommended for CI/CD):** Exporting `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in your terminal session.
* **Shared Config File (Recommended for Local Dev):** Configuring credentials via the **AWS CLI** (`aws configure`). Terraform will default to the standard `$HOME/.aws/` directory.
* **Hardcoding in configuration:** Do not place access keys directly in `.tf` files or commit them to version control.

---
## Terraform Settings Block (`terraform {}`)

The `terraform` block configures Terraform itself rather than a remote infrastructure object.

This section introduces its two most common settings. The `terraform` block supports additional options that are covered later where they become relevant.

* **`required_version`**: Defines the Terraform CLI version or range of versions allowed to execute the configuration (e.g., `required_version = ">= 1.5.0"`).
* **`required_providers`**: Declares provider local names, source addresses, and allowed version constraints.

> **Important:** The `terraform` block accepts only constant values. Its arguments cannot reference input variables, local values, resources, data sources, or other named values, and they cannot call Terraform functions. Terraform must evaluate these settings before it can process the rest of the configuration.

```hcl
terraform {
  required_version = "~> 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

---

## Terraform Versioning

Terraform CLI and provider plugins are separate software components with independent versions. Version constraints help a team use versions that are compatible with the configuration.

### Provider Version Constraints

Provider constraints belong inside `required_providers`. They tell Terraform which provider releases are acceptable; `.terraform.lock.hcl` records the exact version currently selected from that allowed range.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

Common constraint forms include:

| Constraint | Meaning | Examples allowed | Examples rejected |
| :--- | :--- | :--- | :--- |
| `= 6.2.0` or `6.2.0` | Exactly one version | `6.2.0` | `6.2.1`, `6.3.0` |
| `>= 6.2.0` | The specified version or any newer version | `6.2.0`, `7.0.0` | `6.1.0` |
| `>= 6.2.0, < 7.0.0` | Every comma-separated condition must be satisfied | `6.2.0`, `6.9.0` | `6.1.0`, `7.0.0` |
| `~> 6.2.0` | Allow only newer patch releases in the `6.2` series | `6.2.1`, `6.2.9` | `6.3.0`, `7.0.0` |
| `~> 6.2` | Allow newer minor releases while remaining below `7.0.0` | `6.3.0`, `6.10.0` | `7.0.0` |
| `!= 6.2.3` | Exclude one specific version | `6.2.2`, `6.2.4` | `6.2.3` |

The comparison operators `>`, `>=`, `<`, and `<=` can be combined to express other ranges. Root modules commonly use a bounded constraint such as `~>` to avoid automatically accepting a new major provider version. Reusable child modules generally declare only the minimum compatible version so that they do not impose unnecessary upper bounds on their callers.

### Terraform CLI Version

`required_version` does **not** install or select Terraform. It checks the version of the Terraform CLI executable currently running the configuration:

```hcl
terraform {
  required_version = ">= 1.10.0, < 2.0.0"
}
```

With this constraint, Terraform CLI `1.10.0` or a later `1.x` release can run the configuration, but `1.9.8` and `2.0.0` cannot. If the installed CLI does not satisfy the constraint, Terraform stops with an error before planning or applying changes.

The same constraint operators shown above work with `required_version`. Version managers such as `tfenv` can install and switch Terraform CLI versions, but `required_version` itself only validates the active executable.

---

## Dependency Lock File (`.terraform.lock.hcl`)

The dependency lock file records the exact provider versions selected by Terraform and the checksums used to verify downloaded provider packages.

It locks provider selections, not remote module versions. Module versions are selected from each module block's `version` argument or source reference. Modules are explained in [Terraform Modules](05-modules.md#terraform-modules).

Terraform creates or updates it during initialization:

```bash
terraform init
```

### Example Lock File

The generated file looks similar to this:

```hcl
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "6.47.0"
  constraints = "~> 6.47.0"
  hashes = [
    "h1:wLw15aMuMVgPS68hOj8B0IhJr9tMClHdpyIkucdNJ60=",
    "zh:16379546c8b3ebcd6dfe6a5d6b69eb243202585fbd4786e1207bf97004b60799",
    "zh:2ab74c8cd808d1206e4885cbe54433d33b63a257a2ff6b177f6e10b367fabb26",
    "zh:2e5142d5b41ab2bf33e408c040c1540260508a5f2b3dedcda805749611d1c044",
    "zh:5428f836b8184be2922652438784c275565e882cec732cc64ba6ed40cf1e4edb",
    "zh:7927df3cf86cb67be4b0f397dc8d9ce4c7fc4d61d2bbcb091ea9420395f909c5",
    "zh:915b94b53bbfc95ed7f1dcc353a8b20b54cabb362c2304d92bc45d04dc4d0802",
    "zh:9b12af85486a96aedd8d7984b0ff811a4b42e3d88dad1a3fb4c0b580d04fa425",
    "zh:9df44c98ce7939cdad234358b1c4778d42f7f485fb14ff5e340b061b2f86ce40",
    "zh:acb2c2f6f8de5361f3ee2f7fbeab9ca23cef05fc5559abb6d99124a979239359",
    "zh:c1c7b63502380987b6fb51d7ea0c03fe01ec105170acfe0146b28d4eb6173a91",
    "zh:cc50e06c2a9759b3a93442887276e8c8a5b1722fe1714e628f28a57938845e3f",
    "zh:ccac3cfc441914df16ed9f1029fe047446702cd576061a8acc6e07a06be669b3",
    "zh:cdd918479cd9dda1ff67b9d13129862b48db3f58085b318208fb55b4886e4153",
    "zh:da8a6b187750b4fb373697d4cbb58a29ac8a689bfb842129146e1451b6d8a4f1",
    "zh:de0f3b71225f44002db8230c7504ae7b4250124b32bc3bc99e08eff48f60f59e",
  ]
}
```

* **`provider` address:** Identifies the provider publisher and name.
* **`version`:** Records the exact provider version Terraform selected.
* **`constraints`:** Records the version rule from the Terraform configuration.
* **`hashes`:** Contains checksums Terraform uses to verify that downloaded provider packages have not changed. Terraform may record multiple valid hashes automatically.

You normally review and commit this file, but you do not edit it manually.

### What the Lock File Provides

* Reproducible provider selections across developer machines and CI/CD
* Checksum verification of downloaded provider packages
* Reviewable provider upgrades in version control
* Protection from silently selecting a newer compatible provider during every initialization

### Version Constraint vs. Lock Selection

```hcl
version = "~> 6.0"
```

The configuration constraint defines which versions are allowed. The lock file records the exact version currently selected from that allowed range.

To intentionally select newer versions that still satisfy the constraints, run:

```bash
terraform init -upgrade
```

Review the resulting lock-file diff and test the provider upgrade before committing it.

### Important Rules

* Commit `.terraform.lock.hcl` for each separate Terraform project directory.
* Do not edit the lock file manually.
* Do not commit the `.terraform/` directory.

---

## Multiple Provider Configurations

Terraform can use multiple configurations of the same provider. Common use cases include deploying to multiple AWS regions or using different AWS accounts and roles.

For a given provider local name, Terraform can have at most one default configuration: the `provider` block without an `alias`. You cannot declare two independent unaliased configurations for the same local provider name. Every additional configuration must have its own unique `alias`.

One configuration should normally remain unaliased so that it acts as the default. Resources that need another configuration select an alias through the `provider` meta-argument.

### Why Keep a Default Configuration?

If all configurations for a provider have aliases, there is no explicitly configured default. Terraform then treats an empty provider configuration as the default.

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

resource "aws_s3_bucket" "east_logs" {
  bucket_prefix = "east-logs-"
}

resource "aws_s3_bucket" "west_logs" {
  provider      = aws.west
  bucket_prefix = "west-logs-"
}
```

The `east_logs` resource uses the default provider. The `west_logs` resource selects the aliased provider using the `provider` meta-argument.

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

## Common Project Layout and Comments

Terraform combines all `.tf` files in one working directory into a single configuration. The filenames below are common organizational conventions, not required entry points:

* **`main.tf`**: Commonly contains the primary resource declarations.
* **`variables.tf`**: Declares input variables, their data types, and default values.
* **`outputs.tf`**: Declares values that Terraform exposes after an apply, such as generated public IP addresses.
* **`backend.tf`**: Optionally keeps remote backend configuration in a dedicated file.
* **`terraform.tfvars`**: Supplies values for declared input variables and is loaded automatically.

> **Note:** The `backend.tf` filename is an organizational convention. Terraform reads all `.tf` files in the working directory together.

Terraform creates `terraform.tfstate` automatically when the default local backend records state. It is runtime data rather than a configuration file that you create or organize manually. Do not edit it by hand. Remote backends store state in their configured remote location instead of relying on this local state file.

<details>
<summary><strong>Expand the complete multi-file example</strong></summary>

The following structure separates a small configuration by responsibility:

```text
example/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── versions.tf
```

```hcl
# variables.tf
variable "environment" {
  description = "Environment represented by this configuration"
  type        = string
  default     = "development"
}
```

```hcl
# main.tf
resource "terraform_data" "example" {
  input = var.environment
}
```

```hcl
# outputs.tf
output "environment" {
  description = "Environment stored by the terraform_data resource"
  value       = terraform_data.example.output
}
```

```hcl
# terraform.tfvars
environment = "staging"
```

```hcl
# versions.tf
terraform {
  required_version = ">= 1.10.0"
}
```

Terraform combines the `.tf` files into one configuration. `terraform.tfvars` supplies the value for the input declared in `variables.tf`; `main.tf` uses that input; and `outputs.tf` exposes the resource result. None of these filenames determines execution order—the reference from `terraform_data.example` to `var.environment` and the output reference to the resource describe the relationships.

</details>

For a complete runnable exercise using this layout, see [Lab 0: Terraform Workflow and Variable Precedence](../practice/lab_00/lab_00.md).

### Comments in Terraform Code

Terraform supports three different syntax styles for comments:

1. **The `#` Symbol (Single-Line):** This is the idiomatic style recommended by HashiCorp.
   ```hcl
   # This is a standard single-line comment
   resource "aws_vpc" "main" {
     cidr_block = "10.0.0.0/16"
   }
   ```

2. **The `//` Symbol (Single-Line):** This serves the exact same purpose as `#`. It is often used by developers coming from C, Java, or Go backgrounds, but `#` remains the official standard.
   ```hcl
   // This is also a valid single-line comment
   ```

3. **The `/* ... */` Block (Multi-Line):** Valid for multi-line comments, although consecutive `#` comments are usually easier to maintain.
   ```hcl
   /* This configuration creates the core network.
      Review CIDR changes before applying them.
   */
   ```

---



## Data Types

| Type Classification | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| **Primitive** | `string` | Text characters | `"t3.micro"` |
| **Primitive** | `number` | Numeric values | `3` or `3.14` |
| **Primitive** | `bool` | Boolean logic | `true` or `false` |
| **Collection** | `list` | Ordered sequence of values | `["us-east-1a", "us-east-1b"]` |
| **Collection** | `map` | String keys with values of one consistent type | `{ env = "prod", owner = "devops" }` |
| **Structural** | `object` | Complex grouping of distinct types | `{ name = "app", port = 80 }` |

> **Exam Tip — Automatic Type Conversion:** If an input variable declares `type = string` but receives the number `1`, Terraform does not fail; it converts the value to the string `"1"`. This applies whether `1` is supplied as the variable's default or through an input source such as a `.tfvars` file. Automatic conversion fails only when the supplied value is incompatible with the required type. Even when conversion is possible, prefer writing a matching value such as `default = "1"` to make the intended type explicit.

---

## Complex Data Types (`object` and `set`)

While primitive types (`string`, `number`, `bool`) are simple, advanced deployments require complex structural types.

* **`set`:** A collection of unique, unordered values. Unlike a `list`, a set cannot contain duplicate items and does not support numeric indexing such as `[0]`. The `toset()` function converts another collection to a set. [`for_each` vs. `count`](06-configuration.md#advanced-looping-for_each-vs-count) shows how sets work with `for_each`.
* **`object`:** A structural type with named attributes that may each have a different type. Its type constraint acts like a schema for the accepted attributes.

```hcl
variable "server_config" {
  type = object({
    name        = string
    port        = number
    is_internal = bool
  })
}
```

---

## Variables and Output Values

Variables allow you to keep `.tf` files dynamic and reusable.

**Definition (`variables.tf`):**
```hcl
variable "deployment_name" {
  type        = string
  description = "Name assigned to this deployment"
  default     = "web"
}
```

**Referencing (`main.tf`):**
```hcl
resource "terraform_data" "deployment" {
  input = var.deployment_name
}
```

### Variable Assignment Precedence (Lowest to Highest)

For local CLI runs, Terraform uses the following precedence. Sources later in this list override earlier sources:

1. Default values in the `variable` block.
2. Environment variables (`TF_VAR_<name>`).
3. The `terraform.tfvars` file.
4. The `terraform.tfvars.json` file.
5. Any `*.auto.tfvars` or `*.auto.tfvars.json` files, processed in lexical filename order.
6. The `-var` and `-var-file` CLI arguments, processed in the order provided.

HCP Terraform has its own variable and variable-set behavior, discussed in [HCP Terraform and Terraform Enterprise](07-hcp-terraform.md#hashicorp-cloud-platform-hcp-terraform-and-terraform-enterprise).

### Best Practice for Multi-Environment Assignments

Declare variables without defaults when users or automation must provide them, then assign values in environment-specific files such as `prod.tfvars` or `dev.tfvars`.

```bash
terraform apply -var-file="prod.tfvars"
```

### Output Values

An `output` block exposes a selected value from the Terraform configuration. Outputs commonly display useful information after an apply, such as resource IDs, IP addresses, endpoints, and generated names. Automation can also retrieve these values with the `terraform output` command.

```hcl
output "instance_id" {
  description = "ID of the application server"
  value       = aws_instance.application.id
}
```

Each output has a local name and a `value` argument. The `value` can reference input variables, resource attributes, and other expressions available in the configuration.

After an apply, Terraform displays the declared outputs. You can query them later with `terraform output`, explained in [Querying Outputs](03-core-workflow.md#querying-outputs).

> **Important:** An output is not automatically secret. Mark sensitive output values with `sensitive = true`, as explained in [Sensitive Input Variables and Outputs](06-configuration.md#sensitive-input-variables-and-outputs).

---
