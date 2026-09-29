# Lab 15: Provider Aliases and Module Provider Mapping

## Objective

Your platform team needs one reusable module to report available AWS zones from two Regions. The module should describe which provider configurations it expects without embedding concrete Regions or credentials inside the child module.

In this lab, you will configure AWS for `us-east-1` and `us-west-2` in the root module, pass both configurations explicitly to the child, and query each Region through a separate local provider name. You will then test how changing the mapping affects the module and why Terraform normally needs an unaliased default provider configuration.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Completed.

* [Root module](./main.tf)
* [Child module](./modules/regional_inventory/main.tf)
* [Child outputs](./modules/regional_inventory/outputs.tf)

When completed, this implementation should:

* Configure one default and one aliased AWS provider in the root module.
* Declare the provider aliases expected by a reusable child module.
* Map concrete root configurations to the child's local provider names.
* Demonstrate common errors involving duplicate defaults and all-aliased configurations.

Validation commands:

```bash
terraform fmt -check -recursive
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Distinguishing provider requirements from configurations
* Keeping one unaliased default provider
* Declaring an alternate configuration with `alias`
* Passing configurations through a module `providers` map
* Declaring child aliases with `configuration_aliases`
* Understanding the implied empty default configuration

## Prerequisites

* Review [Multiple Provider Configurations](../../README.md#multiple-provider-configurations) and [The Provider Rule](../../README.md#the-provider-rule-exam-trap).
* Configure AWS credentials that can describe Availability Zones in `us-east-1` and `us-west-2`.

This lab reads AWS metadata and creates no remote resources.

## Project Structure

```text
lab_15/
├── main.tf
├── lab_15.md
└── modules/
    └── regional_inventory/
        ├── main.tf
        └── outputs.tf
```

## Step-by-Step Requirements

Build the root and child module files in the order shown below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Build and Test the Two-Region Module</strong></summary>

<details>
<summary>Two-Region provider mapping</summary>

The root module owns the concrete AWS Regions and credentials. The reusable child module declares two provider names for its regional queries, and the caller decides which configured AWS provider each name receives.

A provider requirement selects a plugin and version source. A `provider` block configures one instance of that plugin. A reusable child module declares requirements and expected aliases but receives concrete configurations from its caller. Review the provider-alias and module-mapping explanations in the main README before starting Part 1.

</details>

1. In the root `main.tf`:
   * Declare the AWS provider requirement.
   * Configure the unaliased default AWS provider for `us-east-1`.
   * Configure `aws.west` for `us-west-2`.
2. In `modules/regional_inventory/main.tf` and `modules/regional_inventory/outputs.tf`:
   * Declare the AWS provider requirement in the child module's `terraform` block.
   * List `aws.primary` and `aws.secondary` in `configuration_aliases`. These are the provider names that the child expects to receive; they are not AWS Regions and do not configure credentials.
   * Do not add any `provider "aws"` configuration block in the child module.
   * Add one `aws_availability_zones` data source for the primary query and one for the secondary query. Set each data source's `provider` argument to the corresponding child alias.
   * Add one child output that returns both data-source name lists in a single object, with separate `primary` and `secondary` keys.
3. In the root `main.tf`, call the child module with its local source and map the root provider configurations to the aliases declared by the child:

```hcl
providers = {
  aws.primary   = aws
  aws.secondary = aws.west
}
```

The left side names (`aws.primary` and `aws.secondary`) must match the child's `configuration_aliases`. The right side names (`aws` and `aws.west`) must match the provider configurations declared in the root module. Expose the child output through a root output named `regional_inventory`.

Run:

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
terraform apply
terraform output regional_inventory
```

Confirm that:

* The child queries `us-east-1` through `aws.primary`.
* The child queries `us-west-2` through `aws.secondary`.
* No configured `provider "aws"` block exists inside the child module.
* The output contains two independent Availability Zone lists.

</details>

<details>
<summary><strong>Part 2: Reverse the Provider Mapping</strong></summary>

Temporarily reverse the values:

```hcl
providers = {
  aws.primary   = aws.west
  aws.secondary = aws
}
```

Run `terraform plan`. The child code remains unchanged, but the caller changes which real configuration each child alias receives. Restore the original mapping.

Inspect the planned output and confirm that the meaning of `primary` and `secondary` is controlled by the caller's mapping, not hardcoded Regions inside the child.

</details>

<details>
<summary><strong>Part 3: Trigger a Duplicate Default Error</strong></summary>

Temporarily remove `alias = "west"` from the second provider block and run:

```bash
terraform validate
```

Terraform should reject two default AWS configurations in the same module. Restore the alias.

Read the diagnostic and identify that removing the alias did not merge configurations; it created a conflicting second default configuration.

</details>

<details>
<summary><strong>Part 4: Examine the All-Aliased Trap</strong></summary>

This experiment demonstrates what happens when a module has no unaliased default provider. It is not about creating AWS resources; it shows why every resource or module that expects the default `aws` configuration must receive an explicit provider mapping when all root configurations are aliased.

Do not apply this experiment. Add `alias = "east"` to the previously unaliased provider and update the mapping to use `aws.east`.

When every configuration is aliased, Terraform creates an implied empty default configuration. Any resource or module expecting default `aws` would receive that empty configuration unless an alias is selected or passed explicitly.

Restore one unaliased configuration.

Run `terraform validate` after restoring the original arrangement and confirm that the module mapping is valid again.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. What is the difference between `required_providers` and a `provider "aws"` block?
2. Are provider references such as `aws.west` strings?
3. Are aliased provider configurations inherited automatically by child modules?
4. Who defines names such as `aws.primary` and `aws.secondary`, and who decides which configurations they receive?
5. What happens when every provider configuration in a module has an alias?
6. Why should reusable child modules avoid configuring Regions and credentials internally?

<details>
<summary>Review the design questions and answers</summary>

1. `required_providers` selects the plugin source and version constraints; a provider block configures an instance of that plugin.
2. No. They are special provider-configuration references and are not quoted.
3. No. Aliased configurations must be passed explicitly through the module `providers` map.
4. The child declares the local names it expects through `configuration_aliases`; the caller maps real configurations to those names.
5. Terraform creates an implied empty default configuration for resources or modules that still expect the unaliased provider.
6. The caller should control execution context, credentials, Regions, and aliases so the child remains reusable.

The key lesson is that provider plugin requirements, provider configurations, aliases, and module mappings are related but distinct concepts.

</details>

## Cleanup

This lab creates no remote AWS resources. To remove its local state records, run:

```bash
terraform destroy
```

Run `terraform state list` afterward. Since the lab reads only data sources, no remote AWS object requires deletion.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* Only one configuration per provider can be unaliased in a module.
* Additional configurations require unique aliases.
* Resources select aliases with the `provider` meta-argument.
* Modules receive explicit configurations through the `providers` map.
* Child aliases must be declared with `configuration_aliases`.
* All-aliased configurations imply an empty default configuration.

</details>
