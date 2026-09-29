# Modules and Collaboration

Reusable modules, module inputs and outputs, provider rules, sources, publishing, and team collaboration.

## Terraform Modules

According to the official HashiCorp documentation, **a module is a container for resources that are used together.** Modules package related infrastructure configuration behind a reusable interface.

Every Terraform configuration has at least one module:

* **Root module:** The `.tf` files in the working directory where Terraform runs.
* **Child module:** A module called from another module using a `module` block.
* **Calling module:** The module containing that `module` block. A calling module can be the root module or another child module.

Modules can call other modules, but HashiCorp recommends keeping the module tree relatively flat. Excessive nesting and unnecessary wrappers can make configurations harder to understand and reuse. See HashiCorp's official [module development guidance](https://developer.hashicorp.com/terraform/language/modules/develop).

### The Module Data Flow Diagram
Input variables and output values form a child module's public interface.

* **Input variables** accept values from the calling module.
* **Output values** expose selected results to the calling module.

```text
+----------------------------+   input variables   +----------------------------+
| Calling module             | -------------------> | Child module (./ec2)       |
|                            |                      |                            |
| module "my_server" {       |                      | variable "env_type" {}     |
|   source   = "./ec2"       |                      |                            |
|   env_type = "prod"        |                      | resource "aws_instance"   |
| }                          |                      |   "app" { ... }            |
|                            |   output values      |                            |
| module.my_server.node_ip   | <------------------- | output "node_ip" { ... }   |
+----------------------------+                      +----------------------------+
```

### Passing Variables into a Module
When you build a custom child module, you declare input variables to make the module configurable. The calling module supplies values for required variables directly inside the `module` block; variables with defaults are optional.

**1. Inside the Child Module (`./modules/vpc/variables.tf`):**
```hcl
variable "vpc_cidr" {
  description = "The CIDR block for the custom VPC"
  type        = string
}
```

**2. Inside the Calling Module (`main.tf`):**
```hcl
module "custom_vpc" {
  source = "./modules/vpc"

  # Passing the value into the child module's variable
  vpc_cidr = "10.0.0.0/16"
}
```

### Extracting Outputs & Cross-Referencing Resources
A calling module cannot directly reference resource addresses declared inside a child module. The child module must expose any values its caller needs through `output` blocks. Terraform still tracks the child module's resources and dependencies in its graph and state.

**1. Inside the Child Module (`./modules/ec2/outputs.tf`):**
```hcl
output "server_public_ip" {
  description = "The public IP address of the generated server"
  value       = aws_instance.web.public_ip
}
```

**2. Inside the Calling Module (`main.tf`):**
Once the child module declares the output, its caller can reference the value using `module.<MODULE_NAME>.<OUTPUT_NAME>`.

```hcl
module "frontend" {
  source = "./modules/ec2"
}

# Use the child module's output as an argument to another resource.
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.myapp.com"
  type    = "A"
  ttl     = 300

  records = [module.frontend.server_public_ip]
}
```

### Module Sources
The required `source` argument tells Terraform where to retrieve a child module. Common sources include:

* **Local path:** `source = "./modules/vpc"`. A local relative module path must begin with `./` or `../`.
* **Terraform Registry:** `source = "terraform-aws-modules/vpc/aws"`.
* **Version control:** `source = "git::https://github.com/example/terraform-vpc.git?ref=v1.2.0"`.

Constrain Registry module versions to avoid unexpected upgrades:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "application"
  cidr = "10.0.0.0/16"
}
```

The `version` argument applies only to Registry modules. Git sources use the `ref` query parameter to select a branch, tag, or commit. Prefer an immutable release tag or full commit hash instead of an unpinned default branch.

Run `terraform init` after adding or changing a module source or version. Use `terraform init -upgrade` when you want Terraform to reconsider installed versions and select newer versions allowed by the configured constraints. See the official [module source documentation](https://developer.hashicorp.com/terraform/language/modules/configuration).

### Choosing the Right Public Module
When sourcing modules from the public Terraform Registry:
* Consider **Partner modules** when appropriate. Partner modules are reviewed by HashiCorp and expected to be actively maintained by HashiCorp partners.
* A Partner badge does not guarantee that a module has more features or is the best design for your architecture.
* Review ownership, maintenance history, recent releases, documentation, supported Terraform and provider versions, release practices, open issues, and security implications before adopting any module.

See HashiCorp's official [Partner module guidance](https://developer.hashicorp.com/terraform/registry/modules/partner).

### Standard Module Structure (HashiCorp Best Practices)
For reusable modules, HashiCorp recommends the following minimal structure:

```text
.
├── README.md
├── main.tf
├── variables.tf
└── outputs.tf
```

These filenames are organizational conventions understood by people and documentation tooling. Terraform evaluates all `.tf` files in the module directory together, and the root module directory is the only strictly required element of the standard structure.

* **`main.tf`:** The primary entry point; commonly contains resources and nested module calls.
* **`variables.tf`:** Input variable declarations with descriptions and appropriate type constraints.
* **`outputs.tf`:** Output declarations with descriptions.
* **`README.md`:** The module's purpose, usage, prerequisites, and important behavior.

Larger reusable modules may also include:

* **`examples/`:** Complete examples showing how callers use the module.
* **`modules/`:** Nested modules; a nested module with its own README is considered externally usable.
* **`LICENSE`:** Strongly recommended for publicly distributed modules.

See the official [standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure).

### The Provider Rule (Exam Trap)
Reusable child modules must not contain their own `provider` configuration blocks. Provider configurations belong in the root module, but every child module must still declare its own provider source and version requirements in `required_providers`.

In a simple configuration, a child module automatically inherits the matching default provider configuration. Aliased provider configurations are never inherited automatically and must be passed through the module's `providers` map.

If a child module refers to aliased configuration names, it must declare those names using `configuration_aliases`:

```hcl
# Child module
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0"
      configuration_aliases = [aws.src, aws.dst]
    }
  }
}
```

The calling root module maps its provider configurations to the names expected by the child:

```hcl
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_west"
  region = "us-west-2"
}

module "network_connection" {
  source = "./modules/network-connection"

  providers = {
    aws.src = aws.us_east
    aws.dst = aws.us_west
  }
}
```

Reusable child modules should normally declare the minimum provider version they require with a `>=` constraint. The root module should control the overall version-selection policy and can add an upper bound when appropriate. See the official [providers within modules documentation](https://developer.hashicorp.com/terraform/language/modules/develop/providers).

### Requirements for Publishing to the Terraform Registry
The following requirements apply specifically to modules published in the **public** Terraform Registry. Private registries use different publishing workflows.

1. **GitHub Repository:** The code must be hosted on a public GitHub repository.
2. **Strict Naming Convention:** The repository *must* be named exactly: `terraform-<PROVIDER>-<NAME>` *(Example: `terraform-aws-webserver`)*.
3. **Repository Description:** The GitHub repository must have a short description.
4. **Standard Module Structure:** The repository must follow Terraform's standard module structure.
5. **Semantic Version Tags:** At least one release tag must use `x.y.z` syntax, optionally prefixed with `v` (e.g., `v1.0.0`).

See the official [public module publishing requirements](https://developer.hashicorp.com/terraform/registry/modules/publish).

---
## Git for Team Collaboration with Terraform

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
git status
git add main.tf variables.tf outputs.tf
git diff --staged
git commit -m "Add network module"
git push origin feature/add-network
```

The team can then review the pull request before the Terraform change is applied.

---
