# 📖 Terraform Core Concepts & Commands Wiki

## 1. Core CLI Commands

* **`terraform init`**: Initializes a new or existing Terraform working directory. The plugins required for the defined providers are automatically downloaded and saved locally in a hidden `.terraform` directory. It also initializes the backend where the state will be stored.
* **`terraform validate`**: Checks your configuration files (`.tf`) for syntax errors and internal consistency without accessing any remote services or providers.
* **`terraform fmt`**: Automatically formats your Terraform configuration files into a canonical style and standard indentation.
* **`terraform plan`**: Reads the current state and compares it against the desired state defined in your code. It outputs an execution plan showing exactly what resources will be created, modified, or destroyed, without actually making any changes.
* **`terraform apply`**: Executes the actions proposed in the `terraform plan`. It makes the necessary API calls to the provider to create, update, or delete infrastructure so that the real-world status matches your configuration code.
* **`terraform destroy`**: Safely deletes all the infrastructure managed by the current Terraform configuration (everything tracked in the `terraform.tfstate` file).
* **`terraform destroy -target`**: Allows you to destroy a specific, single resource without affecting the rest of the infrastructure. 
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

## 3. State Management (Current vs. Desired)

Terraform operates using a **declarative** approach to infrastructure management. 

* **Desired State:** What you write in your configuration files (`.tf`). It describes exactly how you want your infrastructure to look.
* **Current State:** The actual state of your infrastructure existing in the real world (e.g., AWS). Terraform tracks this reality using the `terraform.tfstate` file.
* **The Reconciliation Process:** When you run `terraform plan`, Terraform compares the Current State with your Desired State. It calculates the exact difference and proposes an execution plan. Running `terraform apply` executes that plan to align reality with your code.

---

## 4. Terraform Versioning

Versioning is critical to prevent upstream updates from breaking your infrastructure:

* **Provider Versioning:** Always pin provider versions inside the `required_providers` block (e.g., `version = "~> 4.0"`). The `~>` (pessimistic constraint) allows safe patch updates but prevents major breaking changes.
* **CLI Versioning:** Restrict the Terraform binary version using the `required_version` argument inside the `terraform` block. Tools like `tfenv` are commonly used to manage local binary versions.

---

## 5. Standard Project Architecture

While you can write all code in a single file, standard best practices dictate splitting configurations:

* **`main.tf`**: The primary entry point containing core infrastructure resources.
* **`variables.tf`**: Declares input variables, their data types, and default values.
* **`outputs.tf`**: Extracts useful information after creation (e.g., generated Public IPs).
* **`providers.tf`**: Configures providers and specifies required versions.
* **`terraform.tfvars`**: Automatically passes values to variables without CLI flags.
* **`terraform.tfstate`**: A JSON file storing the Current State. *(Never edit manually!)*
* **`.terraform.lock.hcl`**: A dependency lock file recording exact provider hashes to ensure team consistency.

---

## 6. Attributes & Interpolation

* **Cross-Reference Attributes:** Reference the attribute of one resource to use in a different resource.
    * *Syntax:* `<RESOURCE_TYPE>.<NAME>.<ATTRIBUTE>`
* **String Interpolation:** Insert variable or attribute values into strings.
    * *Syntax:* `"${...}"`

---

## 7. Variables

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

## 8. Data Types

| Type Classification | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| **Primitive** | `string` | Text characters | `"t3.micro"` |
| **Primitive** | `number` | Numeric values | `3` or `3.14` |
| **Primitive** | `bool` | Boolean logic | `true` or `false` |
| **Collection** | `list` | Ordered sequence of values | `["us-east-1a", "us-east-1b"]` |
| **Collection** | `map` | Key-value pairs (strings only) | `{ env = "prod", owner = "devops" }` |
| **Structural** | `object` | Complex grouping of distinct types | `{ name = "app", port = 80 }` |

---

## 9. The `count` Meta-Argument

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
Instances created via count are exact identical copies. If you need distinct configurations (e.g., creating 3 IAM users with different names), `count` fails because AWS will not allow duplicate names. 

### The `count.index` Object
To inject flexibility, `count.index` holds the distinct iteration number (starting from 0).
```hcl
resource "aws_iam_user" "users" {
  count = 3
  name  = "developer-user-${count.index}" # Results in user-0, user-1, user-2
}
```

## 10. Advanced Looping: `for_each` vs `count`

While `count` is useful for identical resources, it introduces significant risks when infrastructure scales. The modern best practice for dynamic resource creation is `for_each`.

### The "Blast Radius" Flaw of `count`
* `count` tracks resources using strict **integer array indexes** (`[0]`, `[1]`, `[2]`).
* If you delete an item from the middle of a list, the remaining items shift positions to fill the gap. 
* Terraform will see this index shift and attempt to **destroy and recreate** unrelated infrastructure, causing unintentional outages (a massive blast radius).

### The `for_each` Solution
* `for_each` accepts a `map` or a `set` of strings, tracking resources by **explicit string keys** (e.g., `["analytics"]`, `["security"]`) instead of numerical indexes.
* If an item is removed, Terraform safely targets only that specific key for destruction, leaving the rest of the infrastructure completely untouched.
* **Extraction Objects:** Inside a `for_each` loop, you access the data using:
  * `each.key`: The string identifier (the map key or set item).
  * `each.value`: The nested data/object attached to that key.

> **Note on Lists:** `for_each` cannot iterate directly over a standard `list(string)`. You must use the `toset()` function to convert the list into a set of unique keys: `for_each = toset(var.my_list)`

---

## 11. Local Values (`locals`)

A `locals` block assigns a name to an expression or value, allowing you to use it multiple times within a module without repeating it. 

* Think of them as temporary variables isolated to your specific `.tf` file.
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

## 12. Essential Terraform Functions

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



## 13. Day 2 Operations & Troubleshooting

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

## 14. Splat Expressions (`[*]`)

A splat expression provides a concise, shorthand syntax to extract a specific attribute from an entire list of objects. It is heavily used in `outputs.tf` files to extract things like IP addresses from a cluster of servers.

Instead of writing a full `for` loop to iterate over the list, the `[*]` operator grabs the data instantly.

* **The Long Way (using a `for` loop):** `[for server in aws_instance.web : server.public_ip]`
* **The Splat Way:** `aws_instance.web[*].public_ip`

Both expressions return a clean list of public IPs: `["203.0.113.1", "203.0.113.2"]`.

> **⚠️ Critical Splat Limitation:** > Splat expressions only work natively on **Lists** and **Tuples**. 
> * If you built your servers using `count` (which outputs a list), `aws_instance.web[*].id` works perfectly.
> * If you built your servers using `for_each` (which outputs a map), the splat will fail. You must convert the map values to a list first: `values(aws_instance.web)[*].id`.


## 15. Terraform Logging & Debugging (`TF_LOG`)

When Terraform fails and the standard console output doesn't give you enough information, you can enable detailed execution logging using environment variables.

* **`TF_LOG`**: Controls the verbosity of the logs. 
  * *Levels (from least to most verbose):* `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`.
  * `TRACE` is the default debugging level and provides the most comprehensive data, including every API call made to AWS.
* **`TF_LOG_PATH`**: By default, logs print to your terminal. You can use this variable to force Terraform to append the logs to a specific file instead.
  * *Setup (Linux/macOS):* `export TF_LOG=TRACE` and `export TF_LOG_PATH=./terraform.log`

---

## 16. Saving and Inspecting Execution Plans

In a production CI/CD pipeline, you never run `terraform apply` blindly. You must guarantee that the plan evaluated in the CI stage is the *exact* plan executed in the deployment stage.

* **`terraform plan -out=<filename>.plan`**: Saves the proposed execution plan to a secure, binary file.
* **`terraform apply <filename>.plan`**: Executes the saved plan directly. *(Notice it does not require an approval prompt, because the plan is already locked).*

### Reading the Binary Plan File
Because the `.plan` file is binary, you cannot open it in a text editor.
* **`terraform show <filename>.plan`**: Translates the binary plan into human-readable text in the terminal.
* **`terraform show -json <filename>.plan`**: Outputs the plan in strict JSON format. 
  * *Pro-Tip:* This is heavily used in automation. You can pipe this JSON into tools like `jq` to parse specific data, or send it to security scanners (like Checkov or OPA) to automatically reject the plan if it violates security policies.

---

## 17. Querying Outputs

* **`terraform output`**: Reads the `terraform.tfstate` file and prints the values of any defined `output` blocks. This is incredibly useful for querying infrastructure data (like a generated Database Endpoint or EC2 Public IP) without having to run a full `terraform plan` or API refresh.

---

## 18. Terraform Settings Block (`terraform {}`)

The `terraform` block does not configure infrastructure; it configures the behavior of Terraform itself. This is critical for team consistency.

* **`required_version`**: Dictates the exact version of the Terraform CLI that is allowed to execute this code (e.g., `required_version = ">= 1.5.0"`).
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
git commit -m "Fix: renamed folder and added lab_10"
---

## 19. Resource Targeting (`-target`)

* **`terraform plan -target=<resource_address>`**
* **`terraform apply -target=<resource_address>`**

**Why use this in production?**
HashiCorp explicitly warns that targeting is an **anti-pattern** for routine operations because it breaks Terraform's holistic view of the infrastructure. However, in production operations, it is a necessary "break-glass" emergency tool used for:

1. **Emergency Hotfixes:** If a security vulnerability requires an immediate port closure on a Security Group, you cannot wait 15 minutes for Terraform to evaluate 2,000 other resources. You target the exact SG, apply it in seconds, and fix the vulnerability.
2. **Untangling Dependency Cycles:** Sometimes a complex deployment fails in a "catch-22" (Resource A needs B, but B failed because of A). Targeting allows you to force one resource to build first, breaking the cycle.
3. **Isolating a Broken Resource:** If a minor DNS record is failing and blocking your entire CI/CD pipeline from deploying critical database updates, you can target the database to ensure the rollout continues while you fix the DNS bug.

---

## 20. Performance Optimization: API Throttling

When managing massive enterprise infrastructure, a standard `terraform plan` must query the cloud provider for the real-time status of every single resource in your state file. This can trigger **Slow API Call Throttling** (e.g., AWS temporarily blocking Terraform for making too many requests per second).

**Best Practices to Resolve Throttling:**
1. **State Decomposition (The Permanent Fix):** Never put an entire company's infrastructure in one `main.tf` file. Break the monolith into smaller, isolated projects/workspaces (e.g., `vpc-network`, `database-tier`, `frontend-apps`).
2. **Resource Targeting:** Use `-target` as a temporary band-aid to bypass the need to refresh the entire architecture.
3. **Skip the Refresh:** Run `terraform plan -refresh=false`. This tells Terraform to trust the local `terraform.tfstate` file completely and skip calling the AWS API. 
   * *Warning:* This is incredibly fast, but highly dangerous if someone manually changed infrastructure in the AWS Console, as Terraform will be blind to that "configuration drift" during the plan phase.

## 21. The `zipmap` Function

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

## 22. Commenting in Terraform Code

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

## 23. The `lifecycle` Meta-Argument

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

## 24. Custom Conditions (`precondition` & `postcondition`)

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

## 25. Resource Dependencies

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

## 26. Complex Data Types (`object` and `set`)

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

## 27. Input Variable Validation

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

## 28. Continuous Validation (`check` blocks)

Introduced in Terraform 1.5, `check` blocks perform validation *outside* the normal resource lifecycle. 

* **Behavior:** A `check` block runs during every `terraform plan` or `terraform apply`. If the check fails, it outputs a **warning**, but it does *not* block or break the deployment. 
* **Use Case:** Monitoring the health of infrastructure (e.g., checking if an API endpoint is returning a 200 HTTP status code).

---

## 29. State Refactoring (`moved` blocks)

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
## 30. Provisioners (The "Last Resort")

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

## 31. Terraform Modules

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
4. **`README.md`**: Mandatory documentation.
5. **`versions.tf`**: Defines required Terraform and provider versions.

### 🚨 The Provider Rule (Exam Trap)
**Never** include a `provider` block (like AWS credentials or regions) inside a Child Module. Providers must be strictly defined in the Root Module. Child modules will automatically inherit that configuration. Hardcoding a provider inside a child module makes it impossible to reuse across multiple regions.

### Requirements for Publishing to the Terraform Registry
If you want to share your custom module publicly, HashiCorp enforces strict rules:
1. **GitHub Repository:** The code must be hosted on a public GitHub repository.
2. **Strict Naming Convention:** The repository *must* be named exactly: `terraform-<PROVIDER>-<NAME>` *(Example: `terraform-aws-webserver`)*.
3. **Release Tags:** You must use Git release tags (e.g., `v1.0.0`) so users can pin specific versions.

---

## 32. Terraform Workspaces (Environment Management)

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

# 📚 Terraform Infrastructure Labs: Master Index

Welcome to the practical lab series for mastering Infrastructure as Code (IaC) with Terraform. This repository outlines the progression from foundational cloud provisioning to advanced enterprise architecture, safe state management, and dynamic looping mechanics.

---

## 📍 Core Foundations

### [Lab 1: The Informant Server (Dynamic Image & Mapping)](#)
* **Objective:** Deploy a foundational EC2 instance that dynamically queries the AWS marketplace for the latest OS image.
* **Concepts Covered:** `provider` configuration, `aws_ami` dynamic data sources, `map(string)` variables, dynamic resource tagging, and `output` extraction.

### [Lab 2: Variable Precedence & State Management](#)
* **Objective:** Establish modular input parameters and understand how Terraform reconciles desired state against real-world cloud architecture.
* **Concepts Covered:** `variables.tf`, `terraform.tfvars`, environment variables, declarative configurations, and state file basics.

### [Lab 3: Scaling Identical Resources](#)
* **Objective:** Deploy a fleet of identical servers without duplicating resource blocks.
* **Concepts Covered:** Introduction to the `count` meta-argument, numerical indexing, and using `count.index` for basic resource differentiation.

---

## 📍 Advanced Data Structures & Looping

### [Lab 4: The Automated Network Topology (`for_each` Approach)](#)
* **Objective:** Deploy isolated VPCs dynamically based on complex nested configurations while automatically sanitizing messy human input errors.
* **Concepts Covered:** `for_each` loops, `local` variables, string manipulation (`lower()`, `trimspace()`, `replace()`), and nested `map(object({}))` structural types.

### [Lab 5: The Index-Based Network (The `count` Approach)](#)
* **Objective:** Deploy the exact same network topology from Lab 4, but strictly using `count` to understand the limitations of index-bound deployments.
* **Concepts Covered:** Overcoming map restrictions using collection functions (`length()`, `keys()`, `values()`), list extraction, and array indexing.

### [Lab 6: The Blast Radius (`count` vs. `for_each`)](#)
* **Objective:** Deploy parallel infrastructure and simulate a Day 2 operations modification (deleting an item) to witness the catastrophic index shift of `count` versus the safe targeting of `for_each`.
* **Concepts Covered:** Side-by-side execution, type conversion (`toset()`), state file locking (`[0]` vs `["key"]`), and safely modifying active production environments.

### [Lab 7: Network Security & Firewalls](#)
* **Objective:** Establish secure network boundaries and control inbound/outbound traffic to your cloud resources.
* **Concepts Covered:** `aws_security_group`, ingress/egress rules, CIDR blocks, port mapping (HTTP/SSH), and attaching security groups to instances (`vpc_security_group_ids`).

### [Lab 8: Server Bootstrapping & Provisioners](#)
* **Objective:** Automate post-deployment server configuration to instantly serve a web application upon creation.
* **Concepts Covered:** `user_data` bash scripts, `remote-exec` and `local-exec` provisioners, SSH `connection` blocks, and local state extraction.

### [Lab 9: Lifecycle Management & Guardrails](#)
* **Objective:** Protect critical infrastructure from accidental deletion and safely navigate AWS dependency deadlocks during resource modifications.
* **Concepts Covered:** The `lifecycle` meta-argument, `create_before_destroy` (bypassing the "in-use" firewall trap), and `prevent_destroy` (hard locks for data vaults).

### [Lab 10: Provider Versioning & Stability](#)
* **Objective:** Future-proof the infrastructure by pinning specific versions to avoid breaking changes from upstream HashiCorp or AWS updates.
* **Concepts Covered:** The `terraform` settings block, `required_providers`, `required_version` constraints, provider lockfiles, and safe initialization upgrades (`init -upgrade`).

---

## 🏆 Architecture Checkpoints

### [Checkpoint 1: The SAA "Multi-AZ Web Tier"](#)
* **Objective:** Architect a highly available, Multi-AZ web environment adhering to AWS Solutions Architect Associate (SAA) standards.
* **Concepts Covered:** Synthesizing dynamic AMIs, `for_each` Availability Zone scaling, variable validation rules, complex `output` mapping using `for` loops, and combining advanced lifecycle guardrails in a single production-ready deployment.