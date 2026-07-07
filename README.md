# 📖 Terraform Core Concepts & Commands Wiki

## 1. Core CLI Commands

* **`terraform init`**: Initializes a new or existing Terraform working directory. The plugins required for the defined providers are automatically downloaded and saved locally in a hidden `.terraform` directory. It also initializes the backend where the state will be stored.
* **`terraform validate`**: Checks your configuration files (`.tf`) for syntax errors and internal consistency without accessing any remote services or providers.
* **`terraform fmt`**: Automatically formats your Terraform configuration files into a canonical style and standard indentation.
* **`terraform plan`**: Reads the current state and compares it against the desired state defined in your code. It outputs an execution plan showing exactly what resources will be created, modified, or destroyed, without actually making any changes.
* **`terraform apply`**: Executes the actions proposed in the `terraform plan`. It makes the necessary API calls to the provider to create, update, or delete infrastructure so that the real-world status matches your configuration code.
* **`terraform destroy`**: Safely deletes all the infrastructure managed by the current Terraform configuration (everything tracked in the `terraform.tfstate` file).
* **`terraform destroy -target`**: Focuses the destroy operation on a particular resource address. Terraform may also include dependencies, so always review the generated plan carefully.
    * *Syntax:* `Resource_Type.Local_Resource_Name`
    * *Example:* `terraform destroy -target=aws_instance.myec2`

> **Note on Removing Resources via Code:** If you comment out or delete a resource block directly in your `.tf` files and run `terraform apply`, Terraform will notice the resource is missing from the Desired State and will automatically destroy it in the cloud. You do not need to run `terraform destroy` for this.

> **Note on `terraform refresh` (Deprecated):**
> * Its original purpose was to query the cloud provider and update the `terraform.tfstate` file to match the real-world status.
> * Nowadays, when you run `terraform plan` or `terraform apply`, Terraform automatically performs a refresh in the background before calculating changes.
> * To safely update your state file to match reality without applying new code changes, the modern command is `terraform apply -refresh-only`. *(Terraform automatically creates a `terraform.tfstate.backup` file before modifying the state for recovery).*

---

## 2. Providers

A provider is a plugin that lets Terraform manage an external API. A resource block declares a resource of a given type (e.g., `aws_instance`) with a given local name (e.g., `myec2`).

### Provider Tiers
| Type | Description |
| :--- | :--- |
| **Official** | Owned and maintained by HashiCorp. |
| **Partner** | Owned and maintained by a technology company that maintains a direct partnership with HashiCorp. |
| **Community** | Owned and maintained by individual contributors. |

* **Namespaces** help identify the organization or publisher responsible for the integration.
* Terraform requires explicit source information for non-HashiCorp providers using the `required_providers` nested block inside the `terraform` configuration block.

### AWS Provider Source Credentials
When authenticating the AWS provider, you have several options:
* **Environment Variables (Recommended for CI/CD):** Exporting `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in your terminal session.
* **Shared Config File (Recommended for Local Dev):** Configuring credentials via the **AWS CLI** (`aws configure`). Terraform will default to the standard `$HOME/.aws/` directory.
* **Hardcoding in the code:** Placing access keys directly in `.tf` files *(Highly **not recommended** due to severe security risks)*.

---

## 3. Multiple Provider Configurations

Terraform can use multiple configurations of the same provider. Common use cases include deploying to multiple AWS regions or using different AWS accounts and roles.

One provider configuration should normally remain unaliased as the default. Additional configurations use the `alias` argument.

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

### Passing an Alias to a Child Module

Aliased provider configurations are not inherited automatically. Pass them explicitly from the root module:

```hcl
module "west_app" {
  source = "./modules/app"

  providers = {
    aws = aws.west
  }
}
```

The child module must still declare its own provider requirement, but it must not contain its own `provider` configuration block.

> **Common Trap:** If every provider block has an alias, Terraform creates an implied empty default configuration. A resource without an explicit `provider` argument may then fail because it tries to use that empty configuration.

---

## 4. Terraform Settings Block (`terraform {}`)

The `terraform` block does not configure infrastructure; it configures the behavior of Terraform itself. This is critical for team consistency.

* **`required_version`**: Defines the Terraform CLI version or range of versions allowed to execute the configuration (e.g., `required_version = ">= 1.5.0"`).
* **`required_providers`**: Dictates the specific cloud provider plugins and their versions.
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

## 5. Terraform Versioning

Versioning is critical to prevent upstream updates from breaking your infrastructure:

* **Provider Versioning:** Always constrain provider versions inside the `required_providers` block. For example, `~> 4.0` allows versions from `4.0.0` up to, but not including, `5.0.0`. Use `~> 4.0.0` to allow patch updates only.
* **CLI Versioning:** Restrict the Terraform binary version using the `required_version` argument inside the `terraform` block. Tools like `tfenv` are commonly used to manage local binary versions.

---

## 6. Dependency Lock File (`.terraform.lock.hcl`)

The dependency lock file records the exact provider versions selected by Terraform and the checksums used to verify downloaded provider packages.

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

## 7. Standard Project Architecture

While you can write all code in a single file, standard best practices dictate splitting configurations:

* **`main.tf`**: The primary entry point containing core infrastructure resources.
* **`variables.tf`**: Declares input variables, their data types, and default values.
* **`outputs.tf`**: Extracts useful information after creation (e.g., generated Public IPs).
* **`backend.tf`**: Optionally keeps remote backend configuration in a dedicated file.
* **`terraform.tfvars`**: Automatically passes values to variables without CLI flags.
* **`terraform.tfstate`**: A JSON file storing the Current State. *(Avoid edit manually!)*

> **Note:** The `backend.tf` filename is an organizational convention. Terraform reads all `.tf` files in the working directory together.

---

## 8. State Management (Current vs. Desired)

Terraform operates using a **declarative** approach to infrastructure management.

* **Desired State:** What you write in your configuration files (`.tf`). It describes exactly how you want your infrastructure to look.
* **Current State:** The actual state of your infrastructure existing in the real world (e.g., AWS). Terraform tracks this reality using the `terraform.tfstate` file.
* **The Reconciliation Process:** When you run `terraform plan`, Terraform compares the Current State with your Desired State. It calculates the exact difference and proposes an execution plan. Running `terraform apply` executes that plan to align reality with your code.

---

## 9. Resources, Arguments, Attributes & Interpolation

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
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  tags = {
    Name = "web-server"
  }
}
```

In this example:
* **`resource`**: Tells Terraform you are declaring infrastructure to manage.
* **`aws_instance`**: The resource type. It comes from the AWS provider and tells Terraform what kind of object to create.
* **`web`**: The local resource name. This is how you identify this resource inside your Terraform code.
* **Arguments:** Values you configure inside the block, such as `ami`, `instance_type`, and `tags`.

### Arguments vs. Attributes
* **Arguments** are values you provide to Terraform as input for a resource.
  * Example: `instance_type = "t3.micro"`
* **Attributes** are values Terraform can read from a resource, often after the resource is created.
  * Example: `aws_instance.web.public_ip`

Some values are both configurable arguments and readable attributes, depending on the resource type. Provider documentation tells you which fields are supported.

### Cross-Reference Attributes
You can reference the attribute of one resource and use it in another resource.

* **Syntax:** `<RESOURCE_TYPE>.<LOCAL_NAME>.<ATTRIBUTE>`

```hcl
resource "aws_eip" "web_ip" {
  instance = aws_instance.web.id
}
```

Here, `aws_instance.web.id` means:
* `aws_instance`: Resource type
* `web`: Local resource name
* `id`: Attribute exported by that resource

Terraform also uses these references to understand dependencies. If an Elastic IP references an EC2 instance ID, Terraform knows the EC2 instance must exist first.

### String Interpolation
String interpolation inserts variables, locals, or resource attributes into a string.

* **Syntax:** `"${...}"`

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "app-logs-${terraform.workspace}"
}
```

Modern Terraform also allows direct references without interpolation when the entire value is only one expression:

```hcl
instance = aws_instance.web.id
```

---

## 10. Variables

Variables allow you to keep `.tf` files dynamic and reusable.

**Definition (`variables.tf`):**
```hcl
variable "my_ec2_ami" {
  type        = string
  description = "AMI ID for the EC2 instance"
  default     = "ami-12345678"
}
```

**Referencing (`main.tf`):**
```hcl
resource "aws_instance" "private_ec2" {
  ami           = var.my_ec2_ami
  instance_type = "t3.micro"
}
```

### Variable Assignment Precedence (Lowest to Highest)
Terraform loads variables in a specific order. The sources at the bottom of this list will override the sources at the top:
1. Default values in the `variable` block.
2. Environment variables (`TF_VAR_<name>`).
3. The `terraform.tfvars` file.
4. The `terraform.tfvars.json` file.
5. Any `*.auto.tfvars` or `*.auto.tfvars.json` files.
6. The `-var` and `-var-file` CLI arguments (Highest priority).

### Best Practice for Multi-Environment Assignments
Define empty variables in `variables.tf`, then assign values in environment-specific files (e.g., `prod.tfvars`, `dev.tfvars`).
```bash
terraform apply -var-file="prod.tfvars"
```

---

## 11. Sensitive Input Variables and Outputs

Terraform uses the `sensitive` argument to hide a value from normal CLI and UI output.

```hcl
variable "database_password" {
  description = "Password used by the database administrator"
  type        = string
  sensitive   = true
}

output "database_password" {
  description = "Database administrator password"
  value       = var.database_password
  sensitive   = true
}
```

Terraform displays sensitive values as `(sensitive value)` in plans and normal output. Expressions derived from a sensitive value usually inherit the sensitive marking.

### Critical Limitation

`sensitive = true` provides redaction, not storage protection. Terraform can still store the real value in state and saved plan files.

| Mechanism | Hidden from normal CLI output? | Omitted from plan and state? |
| :--- | :---: | :---: |
| `sensitive = true` | Yes | No |
| `ephemeral = true` | Not necessarily | Yes |
| `sensitive = true` and `ephemeral = true` | Yes | Yes |
| Provider write-only argument | Yes | Yes |

Use `nonsensitive()` only when intentionally removing the sensitive marking from data that is genuinely safe to reveal.

---

## 12. Data Types

| Type Classification | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| **Primitive** | `string` | Text characters | `"t3.micro"` |
| **Primitive** | `number` | Numeric values | `3` or `3.14` |
| **Primitive** | `bool` | Boolean logic | `true` or `false` |
| **Collection** | `list` | Ordered sequence of values | `["us-east-1a", "us-east-1b"]` |
| **Collection** | `map` | String keys with values of one consistent type | `{ env = "prod", owner = "devops" }` |
| **Structural** | `object` | Complex grouping of distinct types | `{ name = "app", port = 80 }` |

---

## 13. Complex Data Types (`object` and `set`)

While primitive types (`string`, `number`, `bool`) are simple, advanced deployments require complex structural types.

* **`set`:** A collection of unique, unordered values. Unlike a `list`, a `set` cannot contain duplicate items, and it does not use an index (`[0]`). You use the `toset()` function to convert a `list` to a `set` for `for_each` loops.
* **`object`:** A structural type that allows you to group multiple distinct variable types under a single variable name. It acts like a strict schema.
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

## 14. Input Variable Validation

You can enforce strict rules on the data humans are allowed to pass into your variables. If the input fails the rule, Terraform rejects the plan before making any API calls.
```hcl
variable "image_id" {
  type        = string

  validation {
    condition     = length(var.image_id) > 4 && substr(var.image_id, 0, 4) == "ami-"
    error_message = "The image_id value must be a valid AMI ID, starting with \"ami-\"."
  }
}
```

---

## 15. Local Values (`locals`)

A `locals` block assigns a name to an expression or value, allowing you to use it multiple times within a module without repeating it.

* Local values are available throughout the current module, including across its `.tf` files.
* They are heavily used to transform, clean, or combine messy input variables before passing them to cloud provider resources.

```hcl
locals {
  # Standard local variable
  common_tags = {
    Owner = "DevOps Team"
  }

  # Transforming an input variable using a 'for' expression
  clean_environments = {
    for k, v in var.network_environments : lower(k) => v
  }
}
```
*You reference them in your resources using `local.<name>` (e.g., `local.common_tags`).*

---

## 16. Essential Terraform Functions

Terraform includes built-in functions to transform and combine values. You cannot define custom functions; you must use what the language provides.

### Collection Functions (Used to hack maps for `count` loops)
* **`length(collection)`**: Returns the total number of items in a map, list, or string. Essential for dynamically defining `count`.
* **`keys(map)`**: Extracts all the keys from a map and returns them as a flat, ordered list.
* **`values(map)`**: Extracts all the values/objects from a map and returns them as a flat, ordered list.

### String Manipulation Functions (Used for input sanitization)
* **`lower(string)`**: Converts all letters in a string to lowercase (critical for AWS naming constraints).
* **`trimspace(string)`**: Removes any accidental spaces from the beginning and end of a string.
* **`replace(string, search, replace)`**: Searches a string and replaces specific characters.
  * *Example:* `replace("my-vpc", "-", "_")` returns `"my_vpc"`.

---

## 17. Commenting in Terraform Code

Clear documentation inside your `.tf` files is critical for Day 2 operations and team collaboration. Terraform supports three different syntax styles for comments:

1. **The `#` Symbol (Single-Line):** This is the standard, most common, and preferred way to write single-line comments in Terraform (HashiCorp configuration language standard).
   ```hcl
   # This is a standard single-line comment
   resource "aws_vpc" "main" { ... }
   ```

2. **The `//` Symbol (Single-Line):** This serves the exact same purpose as `#`. It is often used by developers coming from C, Java, or Go backgrounds, but `#` remains the official standard.
   ```hcl
   // This is also a valid single-line comment
   ```

3. **The `/* ... */` Block (Multi-Line):** Used for writing long explanations, temporarily disabling large blocks of code during troubleshooting, or creating file headers.
   ```hcl
   /* This module deploys the core networking infrastructure.
   It creates the VPC, public subnets, and internet gateways.
   DO NOT modify the CIDR blocks without team approval.
   */
   ```

---

## 18. The `count` Meta-Argument

* **Purpose:** To deploy a pool of identical resources without writing duplicate resource blocks.
* **Mechanism:** Accepts a whole number and creates that many instances.

```hcl
resource "aws_instance" "my_ec2" {
  ami           = "ami-09040d770ffe2224f"
  instance_type = "t3.micro"
  count         = 3
}
```

### Limitations of `count`
Instances created with `count` use the same resource block, but their arguments can vary using `count.index`. For collections whose items need stable names or keys, `for_each` is usually safer.

### The `count.index` Object
To inject flexibility, `count.index` holds the distinct iteration number (starting from 0).
```hcl
resource "aws_iam_user" "users" {
  count = 3
  name  = "developer-user-${count.index}" # Results in user-0, user-1, user-2
}
```

---

## 19. Advanced Looping: `for_each` vs `count`

While `count` is useful for identical resources, it introduces significant risks when infrastructure scales. The modern best practice for dynamic resource creation is `for_each`.

### The "Blast Radius" Flaw of `count`
* `count` tracks resources using strict **integer array indexes** (`[0]`, `[1]`, `[2]`).
* If you delete an item from the middle of a list, the remaining items shift positions to fill the gap.
* Terraform may update or replace shifted resource instances, depending on which arguments changed and whether those arguments require replacement.

### The `for_each` Solution
* `for_each` accepts a `map` or a `set` of strings, tracking resources by **explicit string keys** (e.g., `["analytics"]`, `["security"]`) instead of numerical indexes.
* If an item is removed, Terraform safely targets only that specific key for destruction, leaving the rest of the infrastructure completely untouched.
* **Extraction Objects:** Inside a `for_each` loop, you access the data using:
  * `each.key`: The string identifier (the map key or set item).
  * `each.value`: The nested data/object attached to that key.

> **Note on Lists:** `for_each` cannot iterate directly over a standard `list(string)`. You must use the `toset()` function to convert the list into a set of unique keys: `for_each = toset(var.my_list)`

---

## 20. Dynamic Blocks

A `dynamic` block lets you generate repeated nested blocks inside a resource. This is useful when the resource needs multiple child blocks, such as several `ingress` rules inside an AWS Security Group.

* **Use Case:** Avoid copy-pasting repeated nested blocks when the data can come from a variable or local value.
* **Mechanism:** The `dynamic "<BLOCK_NAME>"` block loops over a collection using `for_each`.
* **Template:** The `content` block defines what each generated nested block should look like.

```hcl
variable "web_ingress_rules" {
  type = map(object({
    port = number
    cidr = string
  }))
}

resource "aws_security_group" "web" {
  name = "dynamic-web-sg"

  dynamic "ingress" {
    for_each = var.web_ingress_rules

    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = [ingress.value.cidr]
    }
  }
}
```

> **Key Idea:** `for_each` creates multiple resource instances; `dynamic` creates multiple nested blocks inside one resource.

---

## 21. Splat Expressions (`[*]`)

A splat expression provides a concise, shorthand syntax to extract a specific attribute from an entire list of objects. It is heavily used in `outputs.tf` files to extract things like IP addresses from a cluster of servers.

Instead of writing a full `for` loop to iterate over the list, the `[*]` operator grabs the data instantly.

* **The Long Way (using a `for` loop):** `[for server in aws_instance.web : server.public_ip]`
* **The Splat Way:** `aws_instance.web[*].public_ip`

Both expressions return a clean list of public IPs: `["203.0.113.1", "203.0.113.2"]`.

> **⚠️ Critical Splat Limitation:** Splat expressions only work natively on **Lists** and **Tuples**.
> * If you built your servers using `count` (which outputs a list), `aws_instance.web[*].id` works perfectly.
> * If you built your servers using `for_each` (which outputs a map), the splat will fail. You must convert the map values to a list first: `values(aws_instance.web)[*].id`.

---

## 22. The `zipmap` Function

The `zipmap` function takes two separate lists (one for keys, one for values) and "zips" them together into a single, cohesive `map`.
* **Syntax:** `zipmap(list_of_keys, list_of_values)`
* **Requirement:** Both lists must have the exact same number of elements.

### The Real-World IAM Use Case
Imagine you use a `count` loop to create a batch of IAM users. Terraform outputs those users as a list of objects. If a downstream module or CI/CD script needs to look up a specific user's ARN by their name, a list is useless—you need a dictionary (a map).

By combining **Splat Expressions** `[*]` with `zipmap`, you can instantly generate a highly queryable map of Names to ARNs.

```hcl
resource "aws_iam_user" "team" {
  count = 3
  name  = "developer-${count.index}"
}

# The zipmap Output
output "iam_user_arns" {
  description = "A map of IAM Usernames to their generated ARNs"

  # List 1 (Keys): ["developer-0", "developer-1", "developer-2"]
  # List 2 (Values): ["arn:aws:iam::123:user/developer-0", ...]

  value = zipmap(aws_iam_user.team[*].name, aws_iam_user.team[*].arn)
}
```
**The resulting output in the terminal will look cleanly mapped like this:**
```json
{
  "developer-0" = "arn:aws:iam::123456789:user/developer-0"
  "developer-1" = "arn:aws:iam::123456789:user/developer-1"
  "developer-2" = "arn:aws:iam::123456789:user/developer-2"
}
```

---

## 23. Resource Dependencies

Terraform builds a dependency graph (DAG) to determine the exact order in which to create or destroy resources.

* **Implicit Dependency (The Standard):** Terraform automatically infers dependencies when one resource references the attribute of another. You should rely on this 95% of the time.
* **Explicit Dependency (`depends_on`):** Used when a resource relies on another resource functioning, but does *not* reference its data directly in the code (e.g., an EC2 instance needing an IAM Role Policy attached before it runs a script).
```hcl
resource "aws_instance" "app_server" {
  # Explicitly force Terraform to wait for the policy attachment
  depends_on = [aws_iam_role_policy_attachment.s3_access]
}
```

---

## 24. The `lifecycle` Meta-Argument

By default, Terraform expects to have absolute, strict control over a resource. If a change requires a resource to be replaced, Terraform will destroy the old resource *first*, and then create the new one.

The `lifecycle` nested block allows you to override these default operational behaviors to protect critical infrastructure, ensure zero downtime, or ignore external modifications.

### `create_before_destroy`
* **Default Behavior:** Destroy old ➔ Create new *(Causes downtime).*
* **Lifecycle Override:** Create new ➔ Update state ➔ Destroy old.
* **Use Case:** Zero-downtime deployments (e.g., updating an EC2 instance or a Load Balancer).
```hcl
resource "aws_instance" "web" {
  lifecycle {
    create_before_destroy = true
  }
}
```

### `prevent_destroy`
* **Behavior:** Acts as a hard safety lock. If Terraform generates a plan that attempts to destroy this resource, the plan will fail.
* **Use Case:** Protecting mission-critical resources (e.g., Production RDS Databases, S3 state files).
* *⚠️ Warning:* This does not prevent destruction if you manually delete the entire `resource` block from your code!

### `ignore_changes`
* **Behavior:** Instructs Terraform to ignore specific resource attributes during the planning phase if the real-world state differs from the `.tf` code.
* **Use Case:** Preventing "configuration drift" wars when external systems (like Auto Scaling Groups) dynamically alter a resource.
```hcl
resource "aws_autoscaling_group" "app_asg" {
  lifecycle {
    ignore_changes = [tags, desired_capacity]
    # ignore_changes = all
  }
}
```

### `replace_triggered_by`
* **Behavior:** Forces this resource to be destroyed and recreated if a referenced resource or attribute changes.
* **Use Case:** Recreating an EC2 instance if an SSM parameter containing its startup script gets updated.

---

## 25. Custom Conditions (`precondition` & `postcondition`)

Also located strictly inside the `lifecycle` block, these allow you to validate assumptions about your resources and data sources.

* **`precondition`:** Evaluated *before* the resource is created/updated. It ensures that the inputs or surrounding environment meet strict requirements.
* **`postcondition`:** Evaluated *after* the resource is created/updated. It guarantees that the resulting infrastructure actually looks the way you expect.
```hcl
resource "aws_instance" "secure_server" {
  ami           = "ami-123456"
  instance_type = "t3.micro"

  lifecycle {
    precondition {
      condition     = data.aws_ami.selected.architecture == "x86_64"
      error_message = "The selected AMI must be x86_64 architecture."
    }
  }
}
```

---

## 26. Continuous Validation (`check` blocks)

Introduced in Terraform 1.5, `check` blocks perform validation *outside* the normal resource lifecycle.

* **Behavior:** A `check` block runs during every `terraform plan` or `terraform apply`. If the check fails, it outputs a **warning**, but it does *not* block or break the deployment.
* **Use Case:** Monitoring the health of infrastructure (e.g., checking if an API endpoint is returning a 200 HTTP status code).

---

## 27. Provisioners (The "Last Resort")

Terraform is a **declarative** tool (you describe the end state, and Terraform figures out how to build it). Provisioners break this rule by being **imperative** (executing a step-by-step script).

Because provisioners execute scripts outside of Terraform's control, Terraform cannot track the changes they make in the `.tfstate` file. For this reason, HashiCorp officially considers provisioners a **Last Resort**. You should only use them when standard configuration management tools (like Ansible, Chef, or standard AWS `user_data`) cannot solve the problem.

### `local-exec`
* **Behavior:** Runs a script or command locally on the machine executing Terraform (your laptop, or the CI/CD pipeline server).
* **Use Case:** Triggering an external API to announce a deployment finished, or writing an output IP address to a local text file.
```hcl
resource "aws_instance" "web" {
  # ... other config ...

  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> server_ips.txt"
  }
}
```

### `remote-exec`
* **Behavior:** Logs into the newly created infrastructure over the network and executes commands directly on the machine.
* **Use Case:** Installing software, starting services, or bootstrapping a node.
* **Requirement:** It **must** be paired with a `connection` block so Terraform knows how to authenticate.
```hcl
resource "aws_instance" "web" {
  # ... other config ...

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx"
    ]
  }
}
```

### The `connection` Block
Nested inside the resource, this block provides the network credentials (SSH or WinRM) required by `remote-exec`.
```hcl
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa") # Reads the local private key file
    host        = self.public_ip
  }
```

### Destroy-Time Provisioners
By default, provisioners run immediately *after* a resource is created. You can use `when = destroy` to force a script to run immediately *before* a resource is deleted.
* **Use Case:** Draining connections from a server, or telling a load balancer to stop sending traffic to the node before Terraform destroys it.
```hcl
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Server is being deleted!' > alert.txt"
  }
```

### ⚠️ The Tainted Resource Problem
If a provisioner fails halfway through (e.g., a script hits an error), Terraform marks the entire resource as **tainted**. This means Terraform considers the resource corrupted. The next time you run `terraform apply`, Terraform will automatically destroy the tainted resource and recreate it from scratch.

### Error Handling (`on_failure`)
By default, if a provisioner script fails, Terraform taints the resource (`on_failure = fail`). You can override this behavior so that Terraform ignores the error and continues the deployment without tainting the resource.

* **Warning:** Use this with extreme caution. It can lead to "silent failures" where Terraform reports a successful deployment, but the software on your server is completely broken or missing.

```hcl
resource "aws_instance" "web" {
  # ... other config ...

  provisioner "remote-exec" {
    # If this script fails, print a warning but DO NOT taint the EC2 instance
    on_failure = continue

    inline = [
      "sudo apt-get install -y imaginary-software-that-does-not-exist"
    ]
  }
}
```

---

## 28. Saving and Inspecting Execution Plans

In a production CI/CD pipeline, you never run `terraform apply` blindly. You must guarantee that the plan evaluated in the CI stage is the *exact* plan executed in the deployment stage.

* **`terraform plan -out=<filename>.plan`**: Saves the proposed execution plan to a secure, binary file.
* **`terraform apply <filename>.plan`**: Executes the saved plan directly. It does not require another approval prompt because the actions were previously captured in the saved plan. The plan file is not a state lock and may contain sensitive data.

### Reading the Binary Plan File
Because the `.plan` file is binary, you cannot open it in a text editor.
* **`terraform show <filename>.plan`**: Translates the binary plan into human-readable text in the terminal.
* **`terraform show -json <filename>.plan`**: Outputs the plan in strict JSON format.
  * *Pro-Tip:* This is heavily used in automation. You can pipe this JSON into tools like `jq` to parse specific data, or send it to security scanners (like Checkov or OPA) to automatically reject the plan if it violates security policies.

---

## 29. Querying Outputs

* **`terraform output`**: Reads the `terraform.tfstate` file and prints the values of any defined `output` blocks. This is incredibly useful for querying infrastructure data (like a generated Database Endpoint or EC2 Public IP) without having to run a full `terraform plan` or API refresh.

---

## 30. Resource Targeting (`-target`)

* **`terraform plan -target=<resource_address>`**
* **`terraform apply -target=<resource_address>`**

**Why use this in production?**
HashiCorp explicitly warns that targeting is an **anti-pattern** for routine operations because it breaks Terraform's holistic view of the infrastructure. However, in production operations, it is a necessary "break-glass" emergency tool used for:

1. **Emergency Hotfixes:** If a security vulnerability requires an immediate port closure on a Security Group, you cannot wait 15 minutes for Terraform to evaluate 2,000 other resources. You target the exact SG, apply it in seconds, and fix the vulnerability.
2. **Recovering from a Partial Failure:** Targeting can help complete or repair part of an operation after an earlier apply failed. It cannot resolve a genuine dependency cycle in the configuration; that cycle must be corrected in the code.
3. **Isolating a Broken Resource:** If a minor DNS record is failing and blocking your entire CI/CD pipeline from deploying critical database updates, you can target the database to ensure the rollout continues while you fix the DNS bug.

---

## 31. Day 2 Operations & Troubleshooting

### Forcing Resource Recreation
Sometimes a resource becomes corrupted in the cloud (e.g., someone manually SSH'd in and broke a configuration), but your Terraform code hasn't changed. Because the desired state matches the code, `terraform plan` won't detect the issue.
* **`terraform apply -replace="<resource_address>"`**: Forces Terraform to destroy and recreate a specific resource during the apply phase, ignoring the lack of code changes.
* *Note:* This modern command officially replaces the deprecated `terraform taint` command.
* *Example:* `terraform apply -replace="aws_instance.web_server[0]"`

### Visualizing Dependencies (The DAG)
Terraform determines the exact order to create, modify, or destroy resources by building a mathematical Directed Acyclic Graph (DAG) under the hood.
* **`terraform graph`**: Outputs this visual dependency graph in the raw DOT language format.
* **Generating an Architecture Image:** You can pipe the raw DOT output into rendering tools like **Graphviz** to create a physical, visual map of your deployment dependencies.
  * *Command:* `terraform graph | dot -Tsvg > graph.svg`
  * *(Note: This requires the Graphviz `dot` CLI tool to be installed on your local OS).*

---

## 32. Terraform Logging & Debugging (`TF_LOG`)

When Terraform fails and the standard console output doesn't give you enough information, you can enable detailed execution logging using environment variables.

* **`TF_LOG`**: Controls the verbosity of the logs.
  * *Levels (from least to most verbose):* `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`.
  * Terraform logging is disabled by default. When enabled, `TRACE` is the most verbose logging level and may expose sensitive information.
* **`TF_LOG_PATH`**: By default, logs print to your terminal. You can use this variable to force Terraform to append the logs to a specific file instead.
  * *Setup (Linux/macOS):* `export TF_LOG=TRACE` and `export TF_LOG_PATH=./terraform.log`

---

## 33. Performance Optimization: API Throttling

When managing massive enterprise infrastructure, a standard `terraform plan` must query the cloud provider for the real-time status of every single resource in your state file. This can trigger **Slow API Call Throttling** (e.g., AWS temporarily blocking Terraform for making too many requests per second).

**Best Practices to Resolve Throttling:**
1. **State Decomposition (The Permanent Fix):** Never put an entire company's infrastructure in one `main.tf` file. Break the monolith into smaller, isolated projects/workspaces (e.g., `vpc-network`, `database-tier`, `frontend-apps`).
2. **Resource Targeting:** Use `-target` as a temporary band-aid to bypass the need to refresh the entire architecture.
3. **Skip the Refresh:** Run `terraform plan -refresh=false`. This skips the normal refresh of managed resources before planning. Terraform may still make provider API calls, such as when reading data sources.
   * *Warning:* This is incredibly fast, but highly dangerous if someone manually changed infrastructure in the AWS Console, as Terraform will be blind to that "configuration drift" during the plan phase.

---

## 34. Terraform Modules

According to the official HashiCorp documentation, **a module is a container for multiple resources that are used together.** Modules are the primary way to package and reuse resource configurations with Terraform.

Every Terraform configuration has at least one module, known as its **Root Module**, which consists of the resources defined in the `.tf` files in the main working directory.

A module can call other modules, which lets you include their resources into the configuration in a concise, declarative way. Modules that are called by another configuration are referred to as **Child Modules**.

### The Module Data Flow Diagram
When using modules, you must understand how data enters and exits the isolated module block.

* **Variables** act as the **Inputs**, flowing from the Root Module *into* the Child Module.
* **Outputs** act as the **Returns**, flowing from the Child Module back *out* to the Root Module.

```text
+-----------------------------------+             +----------------------------------+
|           ROOT MODULE             |             |       CHILD MODULE (./ec2)       |
|                                   |  VARIABLES  |                                  |
|  module "my_server" {             | ===========>|  variable "env_type" {}          |
|    source   = "./ec2"             |  (Inputs)   |                                  |
|    env_type = "prod"              |             |  resource "aws_instance" "app" { |
|  }                                |             |    tags = { Env = var.env_type } |
|                                   |   OUTPUTS   |  }                               |
|  resource "aws_dns" "record" {    | <===========|                                  |
|    ip = module.my_server.node_ip  |  (Returns)  |  output "node_ip" {              |
|  }                                |             |    value = aws_instance.app.ip   |
+-----------------------------------+             +----------------------------------+
```

### Passing Variables into a Module
When you build a custom child module, you declare `variables` to avoid hardcoding values. When the Root Module calls that child module, it must supply values for those variables directly inside the `module` block.

**1. Inside the Child Module (`./modules/vpc/variables.tf`):**
```hcl
variable "vpc_cidr" {
  description = "The CIDR block for the custom VPC"
  type        = string
}
```

**2. Inside the Root Module (`main.tf`):**
```hcl
module "custom_vpc" {
  source   = "./modules/vpc"

  # Passing the value into the child module's variable
  vpc_cidr = "10.0.0.0/16"
}
```

### Extracting Outputs & Cross-Referencing Resources
A Root Module cannot natively "see" the resources inside a Child Module. If your child module creates an EC2 instance, the root module does not know its ID or IP address. You must explicitly export that data using an `output` block in the child module.

**1. Inside the Child Module (`./modules/ec2/outputs.tf`):**
```hcl
output "server_public_ip" {
  description = "The public IP address of the generated server"
  value       = aws_instance.web.public_ip
}
```

**2. Inside the Root Module (`main.tf`):**
Once the child module exports the output, you can reference it in other resources within the Root Module using the syntax: `module.<MODULE_NAME>.<OUTPUT_NAME>`

```hcl
module "frontend" {
  source = "./modules/ec2"
}

# Cross-referencing the module's output in a completely different resource
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.myapp.com"
  type    = "A"
  ttl     = 300

  # Calling the element from the module!
  records = [module.frontend.server_public_ip]
}
```

### Module Sources
When defining the `source` argument, Terraform supports various origins:
* **Local Paths:** `source = "./modules/vpc"` *(Must start with `./` or `../`)*
* **Terraform Registry:** `source = "terraform-aws-modules/vpc/aws"`
* **Version Control (Git):** `source = "git::https://github.com/user/repo.git"`

### Choosing the Right Public Module
When sourcing modules from the public Terraform Registry:
* ✅ **Do:** Choose modules with the **"Verified"** badge (maintained by HashiCorp or official partners). Look for high download counts and active community contributions.
* ❌ **Don't:** Avoid using unverified modules created by random individuals, as they might be abandoned or contain security flaws.

### Standard Module Structure (HashiCorp Best Practices)
If you are building custom modules, follow HashiCorp's Standard Module Structure. Separate your code into at least these files:
1. **`main.tf`**: Contains the primary resource blocks.
2. **`variables.tf`**: Defines the input parameters (no hardcoded values).
3. **`outputs.tf`**: Defines the data returned to the Root Module.
4. **`README.md`**: Recommended documentation, especially for reusable or published modules.

### 🚨 The Provider Rule (Exam Trap)
**Never** include a `provider` block (like AWS credentials or regions) inside a Child Module. Provider configurations should be defined in the Root Module. Child modules automatically inherit default provider configurations, while aliased provider configurations must be passed explicitly through the module's `providers` argument. Each child module should also declare its own provider requirements in `required_providers`.

### Requirements for Publishing to the Terraform Registry
If you want to share your custom module publicly, HashiCorp enforces strict rules:
1. **GitHub Repository:** The code must be hosted on a public GitHub repository.
2. **Strict Naming Convention:** The repository *must* be named exactly: `terraform-<PROVIDER>-<NAME>` *(Example: `terraform-aws-webserver`)*.
3. **Release Tags:** You must use Git release tags (e.g., `v1.0.0`) so users can pin specific versions.

---

## 35. Terraform Security Primer

Terraform often handles cloud credentials, database passwords, API tokens, and other sensitive information. Security must cover the configuration, execution environment, saved plans, logs, and state—not only the `.tf` files.

### Core Security Practices

* **Never hardcode secrets:** Do not place passwords, access keys, or tokens directly in Terraform configuration or committed variable files.
* **Use short-lived credentials:** Prefer workload identity, assumed roles, OIDC, or dynamically generated credentials instead of long-lived access keys.
* **Apply least privilege:** Give Terraform only the permissions required for the resources it manages.
* **Protect state and plan files:** Both can contain sensitive values. Use an encrypted remote backend with strict access control, and treat saved plan files as sensitive artifacts.
* **Protect logs:** Debug logs such as `TF_LOG=TRACE` may expose credentials or secret values.
* **Review before applying:** Inspect plans for unexpected replacements, public access, overly broad firewall rules, or privilege changes.
* **Scan and validate:** Use `terraform fmt`, `terraform validate`, policy checks, and security tools in CI/CD.

### Common Secret Sources

Preferred sources include:

* Environment variables supplied by a secure CI/CD platform
* Cloud-native identity systems, such as AWS IAM roles
* HashiCorp Vault or a cloud secrets manager
* Ephemeral values and provider-supported write-only arguments

> **Important:** Adding a secret file to `.gitignore` prevents Git from tracking it, but does not stop Terraform from storing its value in state.

---

## 36. Git for Team Collaboration with Terraform

Git allows multiple engineers to collaborate on the same Terraform codebase safely.

### What Should Be Committed
Commit the Terraform configuration files that describe the desired infrastructure:
* `main.tf`
* `variables.tf`
* `outputs.tf`
* `providers.tf`
* `modules/`
* `.terraform.lock.hcl`
* Example variable files such as `dev.tfvars.example`

### What Should Not Be Committed
Do **not** commit files that contain local machine data, downloaded providers, secrets, or Terraform state:
* `.terraform/`
* `terraform.tfstate`
* `terraform.tfstate.backup`
* `*.tfvars` files if they contain secrets
* Crash logs and local override files

### Basic Team Workflow
```bash
git checkout -b feature/add-network
terraform fmt
terraform validate
terraform plan
git add .
git commit -m "Add network module"
git push origin feature/add-network
```

The team can then review the pull request before the Terraform change is applied.

---

## 37. Terraform and `.gitignore`

A `.gitignore` file prevents Git from tracking local Terraform files that should stay out of the repository.

### Common Terraform `.gitignore`
```gitignore
# Local Terraform provider/plugins directory
.terraform/

# Terraform state files
*.tfstate
*.tfstate.*

# Crash logs
crash.log
crash.*.log

# Sensitive variable files
*.tfvars
*.tfvars.json

# Local override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# CLI config files
.terraformrc
terraform.rc
```

> **Important:** If your team uses non-sensitive shared variable files, commit an example file such as `dev.tfvars.example`, not the real secret file.

---

## 38. Security Risk of Storing Terraform State in Git

The Terraform state file is sensitive and should not be stored in Git.

### Why State Is Sensitive
`terraform.tfstate` may contain:
* Resource IDs
* IP addresses
* Database endpoints
* IAM role details
* Secret values generated or returned by providers
* Plaintext values from some sensitive resource attributes

Even if your `.tf` files do not show a password directly, Terraform state may still contain the real value after creation.

> **Golden Rule:** Terraform code can go in Git. Terraform state should go in a secure remote backend.

---

## 39. Terraform Backend

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

After adding or changing backend configuration, run:
```bash
terraform init
```

Terraform will initialize the backend and may ask whether you want to migrate existing local state to the new backend.

---

## 40. S3 Backend

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
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "company-terraform-state-dev"
    key     = "checkpoint-2/network/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
```

The `key` is the path inside the bucket where the state file will be stored.

```text
s3://company-terraform-state-dev/checkpoint-2/network/terraform.tfstate
```

### Backend Bootstrap Note
The S3 bucket used for Terraform state usually must exist before Terraform can use it as a backend. Many teams create the backend bucket manually once, or create it in a separate bootstrap Terraform project.

---

## 41. State Locking

State locking prevents two people or systems from modifying the same Terraform state at the same time.

### Why Locking Matters
Imagine two engineers both run `terraform apply` against the same infrastructure:
* Engineer A creates a subnet.
* Engineer B modifies the VPC at the same time.
* Both commands try to update the same state file.

Without locking, the state file could become inconsistent or corrupted.

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

## 42. HashiCorp Vault Basics and Why Vault Matters

HashiCorp Vault is a secrets-management system. It centralizes access to secrets and can provide encryption, access policies, auditing, leases, revocation, and dynamically generated credentials.

### Why Vault Is Important

* **Centralized secret storage:** Applications and automation do not need separate copies of the same secret.
* **Fine-grained access control:** Vault policies determine which identities can read or create particular secrets.
* **Dynamic credentials:** Supported secrets engines can generate short-lived database or cloud credentials when requested.
* **Leases and revocation:** Dynamic secrets can expire automatically or be revoked early.
* **Auditability:** Audit devices record requests made to Vault without exposing secret values in ordinary logs.
* **Secret rotation:** Credentials can be rotated centrally without committing new values to source control.

### Basic Development Workflow

The following workflow is suitable only for local learning. Start the development server in one terminal:

```bash
vault server -dev
```

In a second terminal, copy the development root token printed by the server and run:

```bash
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="<development-root-token>"
vault status
vault kv put secret/database username="dbadmin" password="example-only"
vault kv get secret/database
```

> **Warning:** Vault development mode stores data in memory, uses a root token, and is not secure for production.

In production, Vault should use persistent storage, TLS, restricted policies, an appropriate authentication method, and enabled audit devices. Human users and automation should authenticate with scoped identities instead of sharing a root token.

---

## 43. Terraform and Vault Integration

The HashiCorp Vault provider lets Terraform read, configure, and request secrets from Vault.

```hcl
terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

provider "vault" {
  # VAULT_ADDR and VAULT_TOKEN are read from the environment.
}

data "vault_kv_secret_v2" "database" {
  mount = "secret"
  name  = "database"
}

locals {
  database_username = data.vault_kv_secret_v2.database.data["username"]
}
```

Configure authentication outside the Terraform code:

```bash
export VAULT_ADDR="https://vault.example.com"
export VAULT_TOKEN="<short-lived-token>"
terraform plan
```

### Important State Warning

Reading a secret from Vault does not automatically make Terraform state secret-free. If a Vault value is assigned to a normal resource argument, Terraform may store that value in state. Continue protecting the backend, and prefer ephemeral values or write-only arguments when the destination resource supports them.

### Dynamic Cloud Credentials

Vault secrets engines can issue short-lived AWS, Azure, Google Cloud, or database credentials. This reduces the lifetime and impact of a leaked credential and allows Vault to revoke it. A production integration should use narrowly scoped Vault policies and an authentication method suitable for the execution environment, such as JWT/OIDC, AppRole, or cloud-native authentication.

---

## 44. Ephemeral Values and Write-Only Arguments

Terraform 1.10 introduced ephemeral values, and Terraform 1.11 introduced write-only arguments for managed resources.

* **Ephemeral values:** Exist only during the current Terraform operation and are omitted from plan and state files.
* **Write-only arguments:** Provider-supported resource arguments that accept a value without persisting it. Their names commonly end in `_wo`.
* **Version arguments:** Stored non-secret values, commonly ending in `_wo_version`, that tell Terraform when a write-only value must be updated.

Provider support is required. A normal argument does not become write-only merely because `_wo` is added to its name.

### RDS Password Example

This example generates an ephemeral password, sends it to Amazon RDS through the write-only `password_wo` argument, and stores the same password in AWS Systems Manager Parameter Store through another write-only argument.

```hcl
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

locals {
  db_password_version = 1
}

ephemeral "random_password" "database" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "example" {
  identifier          = "secure-example-db"
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = "dbadmin"
  publicly_accessible = false
  storage_encrypted   = true
  skip_final_snapshot = true

  password_wo         = ephemeral.random_password.database.result
  password_wo_version = local.db_password_version
}

resource "aws_ssm_parameter" "database_password" {
  name        = "/example/database/password"
  description = "Administrator password for the example RDS database"
  type        = "SecureString"

  value_wo         = ephemeral.random_password.database.result
  value_wo_version = local.db_password_version
}
```

Terraform does not persist the generated password in its plan or state. The encrypted SSM parameter becomes the system from which authorized applications or operators retrieve it.

To rotate the password, increment `local.db_password_version`. Terraform then generates a new ephemeral password and sends it to both RDS and Parameter Store.

> **Important:** If an ephemeral password is sent only to RDS and not stored in a secrets manager, it is discarded after the run and cannot be recovered from Terraform.

---

## 45. Terraform Workspaces (Environment Management)

While modules help you separate and reuse your *code*, **Workspaces help you separate your *state* (`terraform.tfstate`)**.

Workspaces allow you to use the exact same directory of Terraform code while maintaining completely isolated, independent state files. This is ideal for managing multiple environments (Dev, QA, Prod) without duplicating your `.tf` files.

### How do they work?
By default, you are always working in a workspace named `default`. When you create a new workspace (e.g., `dev`), Terraform creates a blank, isolated state under the hood.
* `terraform workspace new dev`: Creates a new workspace named "dev".
* `terraform workspace select prod`: Switches to the "prod" workspace.
* `terraform workspace list`: Shows all available environments.

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
HashiCorp recommends using Workspaces to test identical architectures in parallel development environments. However, for environments with strict security or compliance requirements (where Production must be completely isolated from Development), **HashiCorp strongly recommends using separate physical directories and code repositories** rather than relying solely on workspaces.

---

## 46. Terraform State Management Commands

Terraform state commands let you inspect or modify Terraform's state file.

> **Important:** These commands modify Terraform's memory of infrastructure. They do not always modify the real cloud resource.

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
Moves a resource address inside the state file.

```bash
terraform state mv aws_instance.old_name aws_instance.new_name
```

Real-world example:
* You rename a resource block from `aws_instance.old_name` to `aws_instance.new_name`.
* Without moving state, Terraform may think the old resource must be destroyed and a new one created.
* `state mv` tells Terraform this is the same real resource with a new Terraform address.

---

## 47. State Refactoring (`moved` blocks)

If you rename a resource in your `.tf` file (e.g., changing `aws_instance.web` to `aws_instance.frontend`), Terraform will think you deleted the old one and want to create a brand new one, causing accidental deletions.

* **The Fix:** The `moved` block safely tells the state file that the resource simply changed addresses, preventing destruction.
* **Workflow:** Write the `moved` block ➔ run `terraform apply` ➔ safely delete the `moved` block from the code later.
```hcl
moved {
  from = aws_instance.web
  to   = aws_instance.frontend
}
```

---

## 48. Terraform Import

`terraform import` brings an existing real-world resource under Terraform management.

Use import when:
* A resource was created manually in the cloud console
* A resource was created by another tool
* You want Terraform to start managing an existing resource instead of creating a new one

### Import Workflow
1. Write a matching resource block in Terraform code.
2. Run `terraform import`.
3. Run `terraform plan`.
4. Adjust the code until Terraform shows no unexpected changes.

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
```

---

## 49. Removed Blocks

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

## 50. Cross-Project Collaboration Using Remote State Data Source

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

> **Important:** Remote state sharing exposes all root module outputs from the other project. Only output values that other projects really need.

---

## 51. HCP Terraform and Terraform Enterprise

**HCP Terraform** is HashiCorp's managed Software as a Service (SaaS) platform for running Terraform collaboratively. **Terraform Enterprise** provides similar collaboration and governance capabilities but runs in infrastructure controlled by the customer.

Both products build on the Terraform CLI workflow by adding centralized state, remote execution, access control, run history, policy enforcement, and integrations.

### Core Structure

```text
Organization
└── Project
    ├── Workspace
    └── Workspace
```

* **Organization:** The top-level administrative boundary containing users, teams, projects, policies, and shared settings.
* **Project:** Groups related workspaces and provides an access-control boundary for teams.
* **Workspace:** Manages a distinct collection of infrastructure. It contains or references the Terraform configuration, variables, state, run history, and workspace settings.
* Every workspace belongs to exactly one project. New organizations include a default project.

> **Exam Tip:** One HCP Terraform workspace generally represents one Terraform root module and one state file. It is not simply another environment selected with `terraform workspace select`.

### HCP Terraform Workspaces vs. CLI Workspaces

| Concept | Terraform CLI Workspace | HCP Terraform Workspace |
| :--- | :--- | :--- |
| Main purpose | Creates multiple state instances for the same configuration | Manages a distinct infrastructure collection |
| Configuration | Uses the current local working directory | Obtained from VCS or uploaded through the CLI/API |
| State | Separate state for each CLI workspace | State and state history are stored in HCP Terraform |
| Execution | Usually runs locally | Runs remotely by default |
| Collaboration | Limited by itself | Includes permissions, run history, policies, and integrations |

### Run Workflows

HCP Terraform supports three primary workflows:

* **VCS-driven:** The workspace is normally linked to a Git repository and a specific branch. HCP Terraform registers a webhook with the VCS provider. When a commit is pushed or merged to the tracked branch, the webhook queues a run that starts with `terraform plan`. Opening or updating a pull request normally triggers a speculative plan that previews changes but cannot be applied. Directory and branch filters can limit which changes trigger runs.
* **CLI-driven:** Commands such as `terraform plan` and `terraform apply` start remote operations, and their output streams back to the local terminal.
* **API-driven:** Automation uploads configuration versions and controls runs through the HCP Terraform API.

In the VCS workflow, the plan is associated with the exact Git commit that produced it. By default, a successful plan waits for an authorized user to confirm the apply; a workspace can also be configured for automatic apply. Every apply is based on a completed plan. Standard runs are queued and processed in order within each workspace so that concurrent operations do not update the same state simultaneously. Plan-only or speculative runs are an exception: they can run without waiting for the normal workspace run queue and can never be applied.

### Execution Modes

* **Remote execution:** HCP Terraform runs Terraform in a temporary remote environment. This is the default and provides a consistent execution environment.
* **Local execution:** Terraform runs on the user's machine or CI worker while HCP Terraform stores the remote state.
* **Agent execution:** HCP Terraform agents execute runs inside private, isolated, or on-premises networks that the hosted runners cannot reach.

### Air-Gapped Terraform Enterprise

An **air-gapped environment** is an isolated network with no direct Internet access. HCP Terraform is a hosted SaaS product and therefore is not deployed inside an air-gapped network. Organizations that require customer-controlled or disconnected infrastructure can self-host Terraform Enterprise in a restricted or air-gapped environment.

Air-gapped deployments must make all required artifacts available inside the restricted network. This normally includes the Terraform Enterprise license and images, Terraform binaries, providers, modules, and any VCS or other services used during runs. Internal registries and mirrors replace public Internet sources. The exact installation and upgrade artifacts depend on the Terraform Enterprise version and deployment method; older Replicated installations use `.airgap` bundles, so that file format should not be treated as a universal requirement for every deployment.

> **Exam Distinction:** Terraform Enterprise supports self-hosted and air-gapped deployment. HCP Terraform is managed and hosted by HashiCorp. An HCP Terraform agent can reach private infrastructure, but that is not the same as installing the HCP Terraform SaaS control plane in an air-gapped network.

### Connecting with the `cloud` Block

The modern Terraform CLI integration uses a `cloud` block. It connects the current configuration to an HCP Terraform or Terraform Enterprise organization and workspace:

```hcl
terraform {
  cloud {
    organization = "example-organization"

    workspaces {
      name = "network-production"
    }
  }
}
```

Authenticate the CLI before initializing the configuration:

```bash
terraform login
terraform init
terraform plan
```

This preserves a familiar local CLI experience: you type normal Terraform commands and see the output in your terminal. With remote execution, however, Terraform actually runs in HCP Terraform using the remote workspace's variables, credentials, state, and configured Terraform version. The state and run history remain centrally available to the team.

In a CLI-driven workspace, `terraform plan` starts a remote speculative plan and `terraform apply` can start a full remote run. In a VCS-driven workspace, the repository remains the source of truth, so configuration changes and apply runs normally flow through commits and the HCP Terraform UI rather than a CLI-driven `terraform apply`.

The `cloud` block can select one workspace by `name` or select workspaces dynamically using `tags`. It cannot be combined with a `backend` block because both configure where Terraform performs state operations. The older `remote` backend still exists, but the built-in `cloud` integration is preferred for modern Terraform configurations.

### Variables and Credentials

An HCP Terraform workspace can store two kinds of variables:

* **Terraform variables:** Supply values to declared input variables, similar to `.tfvars` values.
* **Environment variables:** Configure the run environment, including provider credentials such as `AWS_ACCESS_KEY_ID`.

Variables can be marked sensitive to redact them from the user interface and ordinary logs. Variable sets can share common values across multiple workspaces or projects.

> **Security Reminder:** Redaction does not guarantee that a value is absent from Terraform state. Continue treating state as sensitive data.

### Plans, Collaboration, and Governance

HCP Terraform has multiple editions, including Free and paid plans such as Essentials, Standard, and Premium. The editions provide different limits and capabilities. Core collaboration features are broadly available, while advanced governance, security, health, and scale capabilities are associated with particular editions. Always check the current plan comparison instead of assuming every feature is included in every plan.

Depending on the selected edition, HCP Terraform can provide:

* Remote state storage, state history, and state locking
* Team-based permissions and project-level access control
* VCS integration and remote run history
* Private module and provider registries
* Policy enforcement with Sentinel or OPA
* Run tasks that integrate external security or compliance systems
* Notifications, cost estimates, drift detection, and continuous validation

### Pricing Concept

HCP Terraform offers Free, Essentials, Standard, and Premium cloud editions. Terraform Enterprise is self-managed and uses custom contract pricing. Paid HCP Terraform editions are cumulative: Standard includes the Essentials features, and Premium includes the Standard and Essentials features.

A managed resource is generally a provider-managed resource recorded in an HCP Terraform state file. Individual instances created with `count` or `for_each` contribute to the resource count, while data sources, `null_resource`, and `terraform_data` do not count as managed resources for this purpose.

For pay-as-you-go billing, managed resources are measured hourly. Each partial hour counts as a full hour, and the highest number of managed resources present during that hour determines the charge. Contracted plans may use negotiated rates and discounts.

### Plan Comparison

The following prices were published in **July 2026** and are included as a study reference. Always verify current prices before making a purchasing decision.

| Edition | Published Starting Price | Intended Use and Important Differences |
| :--- | :--- | :--- |
| **Free** | No charge for up to 500 managed resources | Small teams; includes remote state, remote runs, VCS integration, a private registry, SSO, policy enforcement, and run tasks, subject to Free-plan limits |
| **Essentials** | $0.10 per resource/month, rated hourly at $0.00013 | Professional individuals and teams adopting infrastructure as code; includes the core remote workflow, projects, secure variables, team management, and limited test-integrated module publishing |
| **Standard** | $0.47 per resource/month, rated hourly at $0.00064 | Adds standardization and lifecycle-management capabilities such as module deprecation, team notifications and change requests, no-code provisioning, audit logging, drift detection, and continuous validation |
| **Premium** | $0.99 per resource/month, rated hourly at $0.00135 | Adds higher-level security, governance, and self-service capabilities, including module revocation and additional platform actions; includes all Standard and Essentials features |
| **Terraform Enterprise** | Custom contract pricing | Self-managed deployment for organizations requiring control over security, compliance, networking, operations, or air-gapped environments |

> **Exam Focus:** Know that billing and plan selection occur at the organization level, paid editions build on lower editions, RUM counts managed resource instances rather than workspaces or users, and Terraform Enterprise is the self-managed offering. Exact prices are less important than these distinctions.

### Sentinel Policy as Code

**Sentinel** is HashiCorp's policy-as-code framework. HCP Terraform and Terraform Enterprise can evaluate Sentinel policies against the Terraform configuration, state, and generated plan **after `terraform plan` and before `terraform apply`**. This allows an organization to enforce rules before infrastructure changes are made.

Common policies can require mandatory tags, restrict cloud regions or machine sizes, prevent public access, or require approved Terraform versions.

Policies are grouped into **policy sets**, which can be assigned to selected workspaces or applied more broadly. Sentinel has three enforcement levels:

| Enforcement Level | Result When the Policy Fails |
| :--- | :--- |
| **Advisory** | Reports the failure but allows the run to continue |
| **Soft mandatory** | Blocks the run unless an authorized user overrides it; the override is recorded |
| **Hard mandatory** | Blocks the run and has no normal per-policy override |

> **Exam Tip:** Sentinel does not provision infrastructure. It is a governance checkpoint in the run workflow between the plan and apply stages. Sentinel availability and policy-set limits depend on the HCP Terraform edition.

> **Current-Platform Nuance:** In the traditional Sentinel model, a hard-mandatory failure cannot be overridden. Newer policy-evaluation workflows can support a separately configured policy-set override for authorized users, and that setting takes precedence over an individual policy's enforcement level.

### Key Exam Distinctions

* HCP Terraform is hosted by HashiCorp; Terraform Enterprise is customer-managed.
* A workspace combines configuration, variables, state, settings, and run history for one infrastructure collection.
* Remote execution and remote state storage are related but separate capabilities.
* A speculative plan previews changes and cannot apply them.
* A VCS-linked workspace normally watches a Git branch: commits trigger runs, and pull requests trigger speculative plans.
* VCS-, CLI-, and API-driven workflows all use HCP Terraform workspaces.
* Projects group workspaces and help scope team permissions.
* Sentinel evaluates policy after the plan and before the apply.
* Terraform Enterprise, rather than HCP Terraform SaaS, is the option for air-gapped deployment.

---

# 📚 Terraform Infrastructure Labs: Master Index

Welcome to the practical lab series for mastering Infrastructure as Code (IaC) with Terraform. This repository outlines the progression from foundational cloud provisioning to advanced enterprise architecture, safe state management, and dynamic looping mechanics.

---

## 📍 Core Foundations

### [Lab 1: The Informant Server (Dynamic Image & Mapping)](#)
* **Objective:** Deploy a foundational EC2 instance that dynamically queries the AWS marketplace for the latest OS image.
* **Concepts Covered:** `provider` configuration, `aws_ami` dynamic data sources, `map(string)` variables, dynamic resource tagging, and `output` extraction.

### [Lab 2: Multi-S3 Bucket Deployment (Unique Naming Syntax)](#)
* **Objective:** Create multiple globally unique S3 buckets using dynamic AWS account data and indexed naming.
* **Concepts Covered:** `aws_caller_identity` data source, `count`, `count.index`, `format()`, S3 bucket naming, and dynamic tags.

### [Lab 3: The Chameleon Deployment (Advanced Logic)](#)
* **Objective:** Build infrastructure that changes instance size and resource count based on a single environment switch.
* **Concepts Covered:** Boolean variables, conditional expressions, map lookups, dynamic AMI data sources, and conditional `count`.

---

## 📍 Advanced Data Structures & Looping

### [Lab 4: The Index-Based Network (The `count` Approach)](#)
* **Objective:** Deploy network resources from a map while using `count`, so you can understand the index-based limitations directly.
* **Concepts Covered:** Overcoming map restrictions using collection functions (`length()`, `keys()`, `values()`), list extraction, and array indexing.

### [Lab 5: The Automated Network Topology (`for_each` Approach)](#)
* **Objective:** Deploy isolated VPCs dynamically based on complex nested configurations while automatically sanitizing messy human input errors.
* **Concepts Covered:** `for_each` loops, `locals`, string manipulation (`lower()`, `trimspace()`, `replace()`), and nested `map(object({}))` structural types.

### [Lab 6: The Blast Radius (`count` vs. `for_each`)](#)
* **Objective:** Deploy comparable infrastructure with `count` and `for_each`, then remove a middle-list item to compare shifting numeric indexes with stable string keys.
* **Concepts Covered:** Side-by-side execution, type conversion (`toset()`), resource instance addressing (`[0]` vs. `["key"]`), and safely modifying active infrastructure.

### [Lab 7: Nested Resource Loops (Dynamic Blocks)](#)
* **Objective:** Refactor hardcoded Security Group ingress rules into dynamic nested blocks generated from structured input data.
* **Concepts Covered:** Nested block configuration, `dynamic` blocks, `for_each` inside resources, `content`, and iterator-style access.

### [Lab 8: The Bulletproof Data Engine (Validation & Data Wrangling)](#)
* **Objective:** Provision IAM users from validated structured input, enforce safety conditions, and export a clean ARN dictionary.
* **Concepts Covered:** `object` variables, input validation, `for_each`, `toset()`, lifecycle `precondition`, and output `for` expressions.

---

## 📍 Operations, Guardrails & Provisioning

### [Lab 9: Production Guardrails & CLI Operations](#)
* **Objective:** Protect mock production resources, practice safe planning, refactor state addresses, and use emergency CLI operations.
* **Concepts Covered:** `lifecycle`, `prevent_destroy`, `ignore_changes`, saved plans, `moved` blocks, `apply -replace`, and `terraform graph`.

### [Lab 10: Provisioners & Connections (The Danger Zone)](#)
* **Objective:** Use provisioners to run local and remote actions around an EC2 instance lifecycle.
* **Concepts Covered:** `local-exec`, `remote-exec`, `connection` blocks, destroy-time provisioners, and `on_failure = continue`.

---

## 🏆 Architecture Checkpoints

### [Checkpoint 1: Multi-AZ Web Compute Foundation](#)
* **Objective:** Build a resilient compute foundation by distributing EC2 instances across two Availability Zones and applying shared security and storage guardrails.
* **Concepts Covered:** Dynamic AMIs, `for_each` Availability Zone placement, variable validation, `output` mapping with `for` expressions, shared security rules, and lifecycle guardrails.

---

## 📍 Modular Architecture

### [Lab 11: The Modular Migration](#)
* **Objective:** Refactor Checkpoint 1 into a reusable root-module and child-module architecture.
* **Concepts Covered:** Root modules, child modules, local module sources, variable injection, output aggregation, module isolation, and provider inheritance.
