# Terraform Configuration

Expressions, functions, collections, repetition, lifecycle rules, validation, checks, tests, provisioners, and security-related configuration.

## String Templates and Interpolation

String templates combine literal text with values produced by Terraform expressions. Insert an expression into a string with `${...}`:

```hcl
variable "environment" {
  type    = string
  default = "development"
}

resource "aws_s3_bucket" "logs" {
  bucket_prefix = "app-logs-${var.environment}-"
}
```

In this example, Terraform evaluates `var.environment` and inserts its value between the two literal parts of the string.

Interpolation is useful when an expression forms only part of a larger string. When the entire argument is a single expression, use the expression directly without wrapping it in `"${...}"`:

```hcl
input = terraform_data.source.output
```

Local values, introduced in [Local Values](#local-values-locals), and other expressions can also be inserted into string templates.

---
## Input Variable Validation

You can enforce rules on input variable values. If a known input fails its validation rule, Terraform reports an error rather than creating a normal execution plan. The example uses `length()` and `substr()`, which are introduced in [Essential Terraform Functions and Expressions](#essential-terraform-functions-and-expressions).

```hcl
variable "image_id" {
  type = string

  validation {
    condition     = length(var.image_id) > 4 && substr(var.image_id, 0, 4) == "ami-"
    error_message = "The image_id value must start with \"ami-\" and include an identifier after the prefix."
  }
}
```

This introductory condition validates the required prefix, but it does not prove that the value identifies an AMI that exists in AWS. The provider verifies the identifier when Terraform uses it in an AWS operation.

---

## Local Values (`locals`)

A `locals` block assigns a name to an expression or value so it can be reused throughout your Terraform configuration without repeating the same logic.

### Basic Structure

Declare one or more local values inside a `locals` block:

```hcl
locals {
  local_name = expression
}
```

Reference a declared value with `local.<name>`:

```hcl
local.local_name
```

Terraform uses `locals` (plural) for the declaration block and `local` (singular) for references. There is no `local {}` declaration and no `locals.local_name` reference.

* Local values can hold fixed values or calculate new values from variables, resource attributes, and functions. Functions are introduced in [Essential Terraform Functions and Expressions](#essential-terraform-functions-and-expressions).
* They are useful for common tags, naming conventions, repeated expressions, and transformed or combined input values.
* A local value can be referenced from any `.tf` file in the same Terraform working directory.

> **Scope Note:** Local values are available only within the Terraform configuration where they are declared. A separate configuration in another directory does not automatically receive them.

This example derives a local value from an input variable and then uses it in a resource:

```hcl
variable "environment" {
  type    = string
  default = "production"
}

locals {
  name_prefix = "myapp-${var.environment}"
}

resource "terraform_data" "example" {
  input = local.name_prefix
}
```

The value flows through the configuration as:

```text
var.environment -> local.name_prefix -> terraform_data.example.input
```

Local values can also reference one another when that makes a repeated expression clearer:

```hcl
locals {
  application_name = "customer-portal"

  common_tags = {
    Application = local.application_name
    Owner       = "DevOps Team"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "application" {
  bucket_prefix = "${local.application_name}-"
  tags          = local.common_tags
}
```

This declares `application_name` and `common_tags`, referenced as `local.application_name` and `local.common_tags`.

### Local Values vs. Input Variables

Both avoid repeating hardcoded values, but they solve different problems:

| Question | Input Variable (`variable`) | Local Value (`locals`) |
| :--- | :--- | :--- |
| Where does the value come from? | A user, `.tfvars` file, environment variable, CLI argument, or declared default | An expression written inside the Terraform configuration |
| Can it be supplied or overridden from outside the configuration? | Yes | No |
| Main purpose | Allow the same configuration to accept different input values | Name, transform, combine, or reuse values inside the configuration |
| Reference syntax | `var.<name>` | `local.<name>` |
| Typical example | Region, environment name, instance type, or CIDR | Common tags, normalized names, or a value calculated from several inputs |

Use an **input variable** when a user or automation should be able to provide a different value without editing the Terraform configuration. Use a **local value** when the configuration should calculate, name, or control the value internally.

### When Local Values Become a Disadvantage

Local values improve readability when they give a meaningful name to repeated or complicated expressions. Overusing them can make configuration harder to understand:

* A local used only once for a simple literal can force the reader to jump between files without removing complexity.
* Long chains such as `local.a` → `local.b` → `local.c` hide the real value and make troubleshooting difficult.
* Too many generic names such as `local.value` or `local.config` obscure intent.
* Using locals for values that users or automation reasonably need to change makes the configuration less flexible; those values should usually be input variables.
* Large `locals` blocks containing unrelated calculations become difficult to navigate and maintain.

Prefer a local when it removes meaningful duplication or names a transformation. Prefer a direct expression when it is short, obvious, and used only once.

---

## Data Sources (`data` Blocks)

Now that variables, outputs, references, and data types have been introduced, we can distinguish a data source from a managed resource.

A **data source** reads information from a provider without creating or managing the queried object. For example, an `aws_ami` data source can find an existing Amazon Machine Image, and a managed EC2 resource can then use the returned AMI ID.

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
}

output "selected_ami_id" {
  value = data.aws_ami.amazon_linux.id
}
```

The reference syntax is:

```text
data.<DATA_SOURCE_TYPE>.<LOCAL_NAME>.<ATTRIBUTE>
```

In the example, `data.aws_ami.amazon_linux.id` reads the `id` attribute returned by the data source. Terraform normally attempts to read data sources during planning. If a data-source argument depends on a value that is not known until apply, Terraform may defer the read until the apply phase.

> **Key Difference:** A `resource` block manages an object's lifecycle. A `data` block only reads information.

---

## Sensitive Input Variables and Outputs

Terraform uses the `sensitive` argument to hide a value from normal CLI and UI output.

This section builds on the output declaration introduced in [Variables and Output Values](02-terraform-basics.md#variables-and-output-values). Commands for querying outputs are covered in [Querying Outputs](03-core-workflow.md#querying-outputs).

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

Requesting one sensitive output explicitly with `terraform output database_password` displays its real value. The `-raw` and `-json` output modes can also reveal sensitive values, so do not treat the sensitive marker as an access-control mechanism.

### Critical Limitation

`sensitive = true` provides **redaction, not storage protection**:

* In the human-readable output from `terraform plan`, Terraform replaces the value with `(sensitive value)` instead of displaying the plaintext value.
* In a saved plan file created with `terraform plan -out=<filename>`, Terraform still stores the real value. Treat saved plan files as sensitive artifacts.
* In `terraform.tfstate`, Terraform normally stores the real value in plaintext even when it is marked sensitive. The sensitive flag only tells Terraform to redact the value when presenting it.
* Machine-readable output, such as `terraform show -json`, can expose sensitive values from a plan or state file. Do not publish it without protecting or sanitizing it.

| Mechanism | Visible in Normal Plan Text? | Real Value Stored in Saved Plan or State? |
| :--- | :---: | :---: |
| `sensitive = true` | No—shown as `(sensitive value)` | Yes |
| `ephemeral = true` | May require `sensitive = true` for redaction | No |
| `sensitive = true` and `ephemeral = true` | No | No |
| Provider write-only argument | No | No |

Use `nonsensitive()` only when intentionally removing the sensitive marking from data that is genuinely safe to reveal. Terraform functions are introduced in [Essential Terraform Functions and Expressions](#essential-terraform-functions-and-expressions).

> **Note:** Ephemeral values are introduced here only for comparison. We will discuss them in detail in a future section.

---

## Essential Terraform Functions and Expressions

Terraform includes built-in functions that transform and combine values. Terraform configuration cannot define its own functions, although providers can expose provider-defined functions.

### Built-in Functions

Built-in functions use call syntax such as `length(var.names)` or `format("%s-%d", var.name, 1)`.

#### Collection Functions

* **`length(collection)`**: Returns the number of elements in a collection or the number of characters in a string.
* **`keys(map)`**: Returns a list of a map's keys in alphabetical order.
* **`values(map)`**: Returns the map's values in the same key order used by `keys()`.
* **`zipmap(keys, values)`**: Combines one list of keys and one list of values into a map. Both lists must contain the same number of elements.
* **`flatten(list)`**: Replaces directly or indirectly nested lists with their elements to produce one flat list.
  * *Example:* `flatten([["subnet-a", "subnet-b"], ["subnet-c"]])` returns `["subnet-a", "subnet-b", "subnet-c"]`.
* **`compact(list)`**: Removes null and empty-string elements from a list of strings.
  * *Example:* `compact(["web", "", "api", null])` returns `["web", "api"]`.
* **`distinct(list)`**: Removes duplicate elements while preserving the order of the first occurrence.
  * *Example:* `distinct(["east", "east", "west"])` returns `["east", "west"]`.
* **`merge(maps...)`**: Combines maps or objects. When the same key appears more than once, the value from the later argument takes precedence.
  * *Example:* `merge({ owner = "platform" }, { owner = "santiago", env = "dev" })` returns `{ owner = "santiago", env = "dev" }`.

<details>
<summary>Examples using <code>keys()</code>, <code>values()</code>, and <code>zipmap()</code></summary>

For example, `keys()` and `values()` provide two corresponding ordered views of the same map:

```hcl
locals {
  environments = {
    staging = {
      cidr = "10.1.0.0/16"
    }
    production = {
      cidr = "10.2.0.0/16"
    }
  }

  environment_names   = keys(local.environments)
  environment_objects = values(local.environments)
}
```

The expressions produce:

```text
local.environment_names   -> ["production", "staging"]
local.environment_objects -> [production object, staging object]
```

Because both lists use the same key order, selecting position `0` from each returns the name and object for `production`.

```hcl
locals {
  environment_names = ["development", "staging", "production"]
  instance_sizes    = ["t3.micro", "t3.small", "t3.large"]

  instance_size_by_environment = zipmap(
    local.environment_names,
    local.instance_sizes
  )
}
```

The resulting map is:

```text
{
  "development" = "t3.micro"
  "staging"     = "t3.small"
  "production"  = "t3.large"
}
```

After learning [The `count` Meta-Argument](#the-count-meta-argument) and [Splat Expressions](#splat-expressions-), you can use `zipmap()` to pair dynamically created resource names with their IDs, ARNs, or other attributes.

</details>

#### String and Conversion Functions

* **`lower(string)`**: Converts letters in a string to lowercase, which is useful for services that require lowercase names.
* **`upper(string)`**: Converts letters in a string to uppercase.
  * *Example:* `upper("api")` returns `"API"`.
* **`trimspace(string)`**: Removes any accidental spaces from the beginning and end of a string.
* **`replace(string, search, replace)`**: Replaces matching substrings or regular-expression matches in a string.
  * *Example:* `replace("my-vpc", "-", "_")` returns `"my_vpc"`.
* **`split(separator, string)`**: Divides one string into a list wherever the separator appears.
  * *Example:* `split(",", "80,443,8080")` returns `["80", "443", "8080"]`.
* **`join(separator, list)`**: Combines a list of strings into one string with the separator between elements.
  * *Example:* `join("-", ["terraform", "aws", "practice"])` returns `"terraform-aws-practice"`.
* **`tostring(value)`**: Converts a compatible value to a string.
  * *Example:* `tostring(true)` returns `"true"`.
* **`tolist(value)`**: Converts a compatible collection to a list. Converting an unordered set does not restore its original ordering.
* **`toset(value)`**: Converts a compatible collection to a set, removing duplicates and discarding ordering.
  * *Example:* `toset(["api", "api", "web"])` returns a set containing `"api"` and `"web"`.
* **`tomap(value)`**: Converts a compatible object or collection of key/value pairs to a map whose values share one element type.
  * *Example:* `tomap({ region = "us-east-1", env = "dev" })` returns a map of strings.
* **`format(format_string, values...)`**: Builds a string by replacing format specifiers with the supplied values.
  * `%s` formats a value as a string.
  * `%d` formats a numeric value as a decimal integer.

```hcl
format(
  "%s-%s-%d",
  "terraform-associate-lab2",
  "123456789012",
  0
)
```

The result is:

```text
terraform-associate-lab2-123456789012-0
```

The number and order of the values after the format string must match the format specifiers. String interpolation is often simpler for a small expression, but `format()` is useful when a specific reusable formatting pattern makes the result clearer.

### Expressions

Expressions calculate values through Terraform language syntax. Unlike built-in functions, conditional and `for` expressions are not function calls.

#### Conditional Expressions

A conditional expression selects one of two values using a Boolean condition:

```text
condition ? value_if_true : value_if_false
```

```hcl
variable "is_production" {
  type    = bool
  default = false
}

locals {
  instance_type = var.is_production ? "t3.small" : "t3.micro"
  instance_count = var.is_production ? 2 : 1
}
```

Both result expressions should return compatible types so Terraform can determine the final value's type.

#### `for` Expressions

A `for` expression transforms every element in a collection and produces a new collection. It does not create resource instances.

The general list-producing structure is:

```text
[for item in collection : transformed_item]
```

For example, declare the source list first and then transform it in a local value:

```hcl
variable "names" {
  type    = list(string)
  default = [" API ", "WEB "]
}

locals {
  normalized_names = [for name in var.names : lower(trimspace(name))]
}
```

The result is `["api", "web"]`.

A list iteration exposes one item at a time. A map is different because every element is a key/value pair. When the result must keep that relationship, use braces to produce a map and `=>` to associate each result key with its result value:

```text
{
  for key, value in map : new_key => new_value
}
```

Imagine that environment names arrive with inconsistent capitalization and surrounding spaces, but each name is already associated with the correct network object. The configuration needs to clean the names without losing those objects:

```hcl
variable "environments" {
  type = map(object({
    cidr = string
  }))

  default = {
    " Production " = {
      cidr = "10.2.0.0/16"
    }
    STAGING = {
      cidr = "10.1.0.0/16"
    }
  }
}

locals {
  normalized_environments = {
    for key, value in var.environments : lower(trimspace(key)) => value
  }
}
```

The resulting keys are `production` and `staging`, and each key remains paired with its original CIDR object.

Read the map expression from left to right:

```text
for key, value in var.environments → read each original key/object pair
lower(trimspace(key))              → produce the cleaned result key
=> value                           → attach the original object to that key
```

An optional `if` clause filters elements. This example keeps only production servers:

```hcl
variable "servers" {
  type = map(object({
    environment = string
  }))

  default = {
    api = {
      environment = "production"
    }
    test = {
      environment = "development"
    }
  }
}

locals {
  production_servers = {
    for key, value in var.servers : key => value
    if value.environment == "production"
  }
}
```

> **Exam Distinction:** A `for` expression transforms or filters collection values. The `for_each` meta-argument, introduced in [`for_each` vs. `count`](#advanced-looping-for_each-vs-count), creates multiple resource or module instances identified by stable keys.

---

## The `count` Meta-Argument

* **Purpose:** Create multiple instances of a resource from one resource block.
* **Mechanism:** Accepts a non-negative whole number and creates that many instances, addressed by numeric indexes beginning with zero. The value must be known before Terraform performs remote operations.

```hcl
resource "terraform_data" "pool" {
  count = 3
  input = "server"
}
```

### Limitations of `count`

Instances created with `count` use the same resource block, but their arguments can vary using `count.index`. For collections whose items need stable names or keys, `for_each`, introduced in [`for_each` vs. `count`](#advanced-looping-for_each-vs-count), is usually safer.

### The `count.index` Object

Inside a block that uses `count`, `count.index` is the numeric index of the current instance, starting at zero.

```hcl
resource "terraform_data" "servers" {
  count = 3
  input = "server-${count.index}"
}
```

The resulting instance addresses are `terraform_data.servers[0]`, `terraform_data.servers[1]`, and `terraform_data.servers[2]`.

---

## Advanced Looping: `for_each` vs `count`

Both `count` and `for_each` create multiple resource instances. Choose between them based on how each instance should be identified.

A single resource block cannot use both `count` and `for_each`.

### The Index-Shifting Risk of `count`

* `count` tracks resources using strict **integer array indexes** (`[0]`, `[1]`, `[2]`).
* If you delete an item from the middle of a list, the remaining items shift positions to fill the gap.
* Terraform may update or replace shifted resource instances, depending on which arguments changed and whether those arguments require replacement.

### The `for_each` Solution

* `for_each` accepts a `map` or a `set` of strings, tracking resources by **explicit string keys** (e.g., `["analytics"]`, `["security"]`) instead of numerical indexes.
* Its keys or set members must be known before Terraform performs remote operations because they become part of the resource addresses.
* If one key is removed from the collection, the addresses of the other keyed instances do not shift. Terraform can still propose other changes if the configuration or dependencies also changed.
* **The `each` object:** Inside a block using `for_each`, access the current item with:
  * `each.key`: The string identifier (the map key or set item).
  * `each.value`: The nested data/object attached to that key.

The general resource structure is:

```text
resource "<resource_type>" "<local_name>" {
  for_each = <map_or_set_of_strings>

  argument = each.value
}
```

In a typical configuration, declare the collection separately as an input variable:

```hcl
variable "environments" {
  type = map(object({
    size = string
  }))

  default = {
    development = {
      size = "small"
    }
    production = {
      size = "large"
    }
  }
}

resource "terraform_data" "environment" {
  for_each = var.environments

  input = {
    name = each.key
    size = each.value.size
  }
}
```

The expression can be read in stages:

```text
var.environments  -> complete input map
each.key          -> current map key
each.value        -> current object
each.value.size   -> size attribute from the current object
```

The two instance addresses are `terraform_data.environment["development"]` and `terraform_data.environment["production"]`.

A transformed local map can also be supplied to `for_each`:

```hcl
locals {
  normalized_environments = {
    for key, value in var.environments : lower(trimspace(key)) => value
  }
}

resource "terraform_data" "normalized_environment" {
  for_each = local.normalized_environments

  input = {
    name = each.key
    size = each.value.size
  }
}
```

This flow is:

```text
input variable -> for expression -> local map -> for_each -> resource instances
```

The local transformation is optional. `for_each` can use `var.environments` directly when the input keys already have the desired form.

Use `count` when instances are nearly identical and a numeric index is meaningful. Prefer `for_each` when instances have stable names or keys.

### Using a List with `for_each`

`for_each` does not implicitly convert a list to a set. If duplicates and ordering are not meaningful, explicitly convert a `list(string)` with `toset()`:

```hcl
variable "environment_names" {
  type    = list(string)
  default = ["development", "production"]
}

resource "terraform_data" "environment_from_set" {
  for_each = toset(var.environment_names)

  input = each.value
}
```

For a set of strings, `each.key` and `each.value` contain the same string. The resulting addresses are `terraform_data.environment_from_set["development"]` and `terraform_data.environment_from_set["production"]`.

---

## Splat Expressions (`[*]`)

A splat expression provides concise syntax for extracting the same attribute from every element of a list or tuple of objects. For example, it can collect the public IP addresses of resource instances created with `count`.

Instead of writing a full `for` expression, you can use the `[*]` operator:

* **The Long Way (using a `for` loop):** `[for server in aws_instance.web : server.public_ip]`
* **The Splat Way:** `aws_instance.web[*].public_ip`

Both expressions return a clean list of public IPs: `["203.0.113.1", "203.0.113.2"]`.

> **Critical Splat Limitation:** Splat expressions only work natively on **Lists** and **Tuples**.
> * If you built your servers using `count` (which produces a tuple of resource instances), `aws_instance.web[*].id` works.
> * If you built your servers using `for_each` (which outputs a map), the splat will fail. You must convert the map values to a list first: `values(aws_instance.web)[*].id`.

---

## Dynamic Blocks

A `dynamic` block generates repeated nested blocks inside another supported block. This is useful when the number of nested blocks must be determined by input data, such as a variable containing IAM policy statements.

### Anatomy of a Dynamic Block

```hcl
dynamic "statement" {
  for_each = var.policy_statements
  iterator = policy_statement # Optional

  content {
    sid       = policy_statement.key
    effect    = policy_statement.value.effect
    actions   = policy_statement.value.actions
    resources = policy_statement.value.resources
  }
}
```

* **`dynamic "statement"`:** Declares that Terraform must generate nested blocks named `statement`. The parent block's provider schema must support that nested block type.
* **`for_each`:** Selects the collection and determines how many nested blocks Terraform generates. One block is generated for every collection element.
* **`content`:** Defines the arguments placed inside every generated `statement` block.
* **`iterator` (optional):** Changes the temporary name used to access the current collection element inside `content`.

<details>
<summary><strong>How the Optional Iterator Works</strong></summary>

If `iterator` is omitted, Terraform automatically uses the generated block's name. For `dynamic "statement"`, the default iterator is therefore `statement`:

```hcl
dynamic "statement" {
  for_each = var.policy_statements

  content {
    sid       = statement.key
    effect    = statement.value.effect
    actions   = statement.value.actions
    resources = statement.value.resources
  }
}
```

When iterating over a map:

```text
statement.key   → current map key
statement.value → current map value
```

Declaring `iterator = policy_statement` only renames that temporary reference:

```text
statement → policy_statement
```

It does not change the collection, number of iterations, or generated result. A custom name is most useful when it improves clarity or when dynamic blocks are nested.

</details>

> **Limitation:** A `dynamic` block generates nested blocks defined by the parent block's schema. It cannot generate Terraform meta-argument blocks such as `lifecycle`, which is introduced in [The `lifecycle` Meta-Argument](#the-lifecycle-meta-argument).

### Complete Example

```hcl
variable "policy_statements" {
  type = map(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))

  default = {
    DescribeInstances = {
      effect    = "Allow"
      actions   = ["ec2:DescribeInstances"]
      resources = ["*"]
    }
  }
}

data "aws_iam_policy_document" "example" {
  dynamic "statement" {
    for_each = var.policy_statements
    iterator = policy_statement

    content {
      sid       = policy_statement.key
      effect    = policy_statement.value.effect
      actions   = policy_statement.value.actions
      resources = policy_statement.value.resources
    }
  }
}
```

> **Key Idea:** Resource-level `for_each` creates multiple addressed instances; `dynamic` creates multiple nested blocks inside one parent block.

---

## Resource Dependencies

Terraform builds a dependency graph (DAG) to determine the exact order in which to create or destroy resources.

* **Implicit Dependency (Preferred):** Terraform automatically infers dependencies when one resource references an attribute of another. Prefer an implicit dependency whenever a direct reference can express the relationship.
* **Explicit Dependency (`depends_on`):** Used when a resource relies on another resource functioning, but does *not* reference its data directly in the code (e.g., an EC2 instance needing an IAM Role Policy attached before it runs a script).
```hcl
resource "aws_instance" "app_server" {
  # Explicitly force Terraform to wait for the policy attachment
  depends_on = [aws_iam_role_policy_attachment.s3_access]
}
```

---

## The `lifecycle` Meta-Argument

By default, Terraform expects to have absolute, strict control over a resource. If a change requires a resource to be replaced, Terraform will destroy the old resource *first*, and then create the new one.

The `lifecycle` nested block allows you to adjust these default operational behaviors to protect critical infrastructure, reduce downtime, or ignore selected external modifications.

### `create_before_destroy`
* **Default Behavior:** Destroy old, then create new. This causes downtime.
* **Lifecycle Override:** Create new, update state, then destroy old.
* **Use Case:** Reducing downtime during replacement (e.g., updating an EC2 instance or a load balancer).
```hcl
resource "aws_instance" "web" {
  lifecycle {
    create_before_destroy = true
  }
}
```

> **Important:** `create_before_destroy` does not guarantee zero downtime. The provider must be able to create both objects temporarily, and unique-name or capacity constraints can prevent this strategy.

### `prevent_destroy`
* **Behavior:** Rejects a Terraform plan that would destroy the resource while this lifecycle rule remains in its configuration.
* **Use Case:** Protecting mission-critical resources (e.g., production RDS databases or S3 state buckets).
* **Warning:** This does not protect against deletion outside Terraform. It also does not prevent destruction if you remove the entire `resource` block, because the lifecycle rule is then removed with it.

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

## Custom Conditions (`precondition` & `postcondition`)

`precondition` and `postcondition` blocks are lifecycle conditions that validate assumptions about resources, data sources, and supported ephemeral resources.

* **`precondition`:** Evaluated *before* the resource is created/updated. It ensures that the inputs or surrounding environment meet strict requirements.
* **`postcondition`:** Evaluated after Terraform plans or applies the relevant resource or reads a data source. It validates the resulting object before Terraform continues with downstream operations that depend on it.
```hcl
data "aws_ami" "selected" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "secure_server" {
  ami           = data.aws_ami.selected.id
  instance_type = "t3.micro"

  root_block_device {
    encrypted = true
  }

  lifecycle {
    precondition {
      condition     = data.aws_ami.selected.architecture == "x86_64"
      error_message = "The selected AMI must be x86_64 architecture."
    }

    postcondition {
      condition     = self.root_block_device[0].encrypted
      error_message = "The EC2 instance root volume must be encrypted."
    }
  }
}
```

The precondition validates information available before Terraform acts. The postcondition validates the resulting resource after Terraform creates or updates it. If a postcondition fails, Terraform stops downstream operations that depend on the object, but it does not roll back infrastructure changes that have already completed.

Inside a postcondition, `self` represents the particular resource or data-source instance Terraform is currently evaluating. It gives the condition access to that object's resulting attributes, including values returned by the provider after creation or refresh. In this example, `self.root_block_device[0].encrypted` reads the encryption status reported for the EC2 instance being checked.

Use `self` instead of referring to the enclosing object by its full address. The following expression would make the resource refer to itself and therefore create an invalid self-reference:

```hcl
# Invalid inside aws_instance.secure_server
condition = aws_instance.secure_server.root_block_device[0].encrypted
```

The `self` object is available in resource and data-source postconditions. Preconditions instead refer to input variables, local values, data sources, or other resources because they run before Terraform evaluates the enclosing object's resulting provider attributes.

---

## Check Blocks and Continuous Validation

Introduced in Terraform 1.5, `check` blocks perform validation *outside* the normal resource lifecycle.

* **Behavior:** A `check` block runs during every `terraform plan` or `terraform apply`. If the check fails, it outputs a **warning**, but it does *not* block or break the deployment.
* **Use Case:** Monitoring the health of infrastructure (e.g., checking if an API endpoint is returning a 200 HTTP status code).

> **HCP Terraform Note:** A local `check` block runs during plan and apply. HCP Terraform's continuous validation capability can also evaluate checks automatically outside normal infrastructure changes.

The following example queries an application's health endpoint after Terraform has planned or applied the rest of the configuration:

```hcl
terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

check "application_health" {
  data "http" "health_endpoint" {
    url = "https://example.com/health"
  }

  assert {
    condition     = data.http.health_endpoint.status_code == 200
    error_message = "Application health check failed with status ${data.http.health_endpoint.status_code}."
  }
}
```

If the assertion fails, Terraform reports a warning and continues the plan or apply. Use a precondition or postcondition instead when a failed condition must block the operation.

---

## Terraform Tests

Terraform's native testing framework lets module authors describe test runs in files ending with `.tftest.hcl`. Store them in the module directory or, preferably, its default `tests/` directory:

```text
modules/network/
├── main.tf
├── variables.tf
├── outputs.tf
└── tests/
    └── network.tftest.hcl
```

A test file contains one or more `run` blocks. Each run can execute a plan or apply and evaluate `assert` blocks:

```hcl
run "valid_environment" {
  command = plan

  variables {
    environment = "development"
  }

  assert {
    condition     = var.environment == "development"
    error_message = "The test must use the development environment."
  }
}
```

Run the tests from the root directory of the module or root configuration being tested:

```bash
terraform test
```

Use `terraform test -filter=tests/network.tftest.hcl` to select one test file. Tests that use apply mode can create real infrastructure and costs, so use controlled test environments and review cleanup behavior.

| Command | Purpose |
| :--- | :--- |
| `terraform validate` | Check syntax and internal configuration consistency |
| `terraform plan` | Preview changes for the current configuration and state |
| `terraform test` | Execute `.tftest.hcl` test runs and assertions |

> **Exam Tip:** Creating `.tftest.hcl` files with `run` and `assert` blocks does not make normal `validate`, `plan`, or `apply` commands execute the test suite. Use `terraform test`.

---

## Provisioners (The "Last Resort")

Terraform normally asks providers to create and manage infrastructure whose desired configuration can be compared with state. A provisioner is different: it runs an imperative command or script associated with a resource, but Terraform does not model the individual changes that command makes inside the operating system or an external service.

Unless configured with `when = destroy`, a provisioner is a **creation-time provisioner**. Terraform runs it immediately after creating the parent resource, not during every plan or apply. If it fails with the default failure behavior, Terraform stops the apply and marks the resource as tainted because it may be only partially configured. A subsequent apply normally proposes replacing that resource so it can be created and configured again.

HashiCorp recommends exhausting purpose-built alternatives before using provisioners because their side effects cannot be planned and tracked as reliably as provider-managed resources. Depending on the task, alternatives include building an image with Packer, bootstrapping an instance with `user_data` or cloud-init, managing ongoing operating-system configuration with a tool such as Ansible, or using a Terraform provider that directly manages the target system or API. Remote provisioners also require Terraform to have network access and credentials for the target. See HashiCorp's official [provisioner guidance](https://developer.hashicorp.com/terraform/language/provisioners).

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
* **Requirement:** It must have connection settings that tell Terraform how to reach and authenticate to the remote system.

The following example places `connection` inside `remote-exec`, so those settings apply only to that provisioner. Because both blocks are inside `aws_instance.web`, use `self.public_ip` rather than referring to `aws_instance.web.public_ip` from inside its own resource block.

```hcl
resource "aws_instance" "web" {
  # ... other config ...

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }

    inline = [
      "sudo dnf install -y nginx",
      "sudo systemctl enable --now nginx"
    ]
  }
}
```

### The `connection` Block

A `connection` block provides the network address, connection type, user, and authentication details required to reach a remote system over SSH or WinRM. Terraform does not establish this connection merely because the block exists; a remote provisioner such as `remote-exec` uses the settings when it runs.

There are two valid scopes:

* Inside a resource, it provides default connection settings for the provisioners in that resource.
* Inside a provisioner, as in the previous example, it applies only to that provisioner and overrides resource-level defaults.

This resource-level form is useful when multiple remote provisioners share the same connection:

```hcl
resource "aws_instance" "web" {
  # ... other config ...

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = ["sudo dnf install -y nginx"]
  }
}
```

The host must be reachable from the machine running Terraform, and the private key must match the public key installed on the instance. Keep private keys outside the repository and restrict their filesystem permissions.

### Destroy-Time Provisioners
By default, provisioners run immediately *after* a resource is created. You can use `when = destroy` to force a script to run immediately *before* a resource is deleted.
* **Use Case:** Draining connections from a server, or telling a load balancer to stop sending traffic to the node before Terraform destroys it.
```hcl
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Server is being deleted!' > alert.txt"
  }
```

### Creation-Time Failure and Tainted Resources
If a creation-time provisioner fails with the default failure behavior, Terraform marks the resource as **tainted** because it may be only partially configured. During the next `terraform apply`, Terraform normally plans to replace the tainted resource.

A destroy-time provisioner behaves differently. If it fails, Terraform returns an error without destroying the resource and attempts the provisioner again during the next apply. Destroy-time provisioners should therefore be safe to run more than once.

### Error Handling (`on_failure`)
By default, `on_failure = fail` causes a provisioner failure to stop the Terraform operation. When the failing provisioner is a creation-time provisioner, Terraform also taints the resource. Setting `on_failure = continue` tells Terraform to report a warning, ignore the error, and continue without tainting the resource.

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



## Terraform Security Primer

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
* Ephemeral values and provider-supported write-only arguments, explained in [Ephemeral Values and Write-Only Arguments](#ephemeral-values-and-write-only-arguments)

> **Important:** Adding a secret file to `.gitignore` prevents Git from tracking it, but does not stop Terraform from storing its value in state.

---

## Terraform and `.gitignore`

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

## Security Risk of Storing Terraform State in Git

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

## Ephemeral Values and Write-Only Arguments

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
