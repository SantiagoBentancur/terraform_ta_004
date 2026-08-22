# Lab 5: Stable VPC Identities with `for_each`

## Objective

Rebuild the VPC scenario from Lab 4 using `for_each` instead of `count`. The environment map will keep the same keys and object attributes, but each map key will now become the identity of its matching VPC. Add `development` again and compare the plan with Lab 4: Terraform should propose one new VPC without changing the addresses of `production` or `staging`.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Completed.

**[View my Terraform solution](./lab_5.tf)**

When completed, this implementation should:

* Reuse the map-of-objects data model from Lab 4.
* Create one VPC for every map element with `for_each`.
* Use environment names as resource instance identities.
* Demonstrate how adding one key affects only its matching VPC.

Validation commands:

```bash
terraform fmt -check
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Declaring a `map(object(...))`
* Creating keyed resource instances with `for_each`
* Reading the current map element with `each.key` and `each.value`
* Comparing numeric and key-based resource addresses
* Transforming a map with a `for` expression in an operational scenario
* Naming a transformed value with `locals`

## Prerequisites

* Review [`for_each`](../../README.md#the-for_each-solution), [`for` Expressions](../../README.md#for-expressions), [Local Values](../../README.md#local-values-locals), and [String and Conversion Functions](../../README.md#string-and-conversion-functions).
* Configure AWS credentials with permission to create and delete VPCs.

> **Cost Warning:** This lab creates two VPCs. The `development` experiment is plan-only and must not be applied.

## Step-by-Step Requirements

Build the configuration in `lab_5.tf` in the order shown below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Rebuild the Lab 4 VPCs with `for_each`</strong></summary>

<details>
<summary>From numeric positions to map keys</summary>

Lab 4 converted the environment map into ordered key and value lists because `count` identifies resource instances by numeric position. `for_each` can consume the map directly. Terraform then exposes the current key as `each.key` and its associated object as `each.value`.

| Map key | `each.key` | `each.value` | Resource address |
|---|---|---|---|
| `production` | `production` | Production object | `aws_vpc.environment["production"]` |
| `staging` | `staging` | Staging object | `aws_vpc.environment["staging"]` |

This version does not need `keys()`, `values()`, `count`, or `count.index`. The environment name itself identifies the resource instance.

</details>

1. Configure AWS for `us-east-1`.
2. Declare `environments` using the same object type and default values as Lab 4:
   * Each object contains `cidr` as a string and `priority` as a number.
   * `staging` uses CIDR `10.1.0.0/16` and priority `2`.
   * `production` uses CIDR `10.2.0.0/16` and priority `1`.
3. Create `aws_vpc.environment`.
   * Use the environment map directly with `for_each`.
   * Read the CIDR from the current object.
   * Set `instance_tenancy` to `default`.
   * Add the following tags:
     * `Name`: prefix the current environment key with `vpc-`.
     * `Environment`: use the current environment key.
     * `Priority`: convert the current object's numeric priority to a string.
     * `ManagedBy`: set it to `Terraform`.

Run:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

Confirm that:

* The plan proposes exactly two VPCs.
* The addresses contain `"production"` and `"staging"`, not `[0]` and `[1]`.
* Each environment key remains paired with the correct CIDR and priority.

</details>

<details>
<summary><strong>Part 2: Apply and Inspect the Key-Based Addresses</strong></summary>

Apply the default configuration and inspect the state:

```bash
terraform apply
terraform state list
terraform state show 'aws_vpc.environment["production"]'
terraform state show 'aws_vpc.environment["staging"]'
```

Confirm that the state addresses use the two environment names and that the attributes and tags match their corresponding objects.

</details>

<details>
<summary><strong>Part 3: Add `development` and Observe Key-Based Behavior</strong></summary>

Temporarily add the same element used in the Lab 4 experiment:

```hcl
development = {
  cidr     = "10.0.0.0/16"
  priority = 3
}
```

Run `terraform plan`, but do not apply it.

Confirm that:

* Terraform proposes creating `aws_vpc.environment["development"]`.
* The existing `production` and `staging` addresses remain unchanged.
* The summary reports `1 to add, 0 to change, 0 to destroy`.

After inspecting the plan, remove the temporary `development` element. Run `terraform plan` again and confirm that the configuration returns to no changes.

</details>

<details>
<summary><strong>Part 4: Normalize Keys Before They Become Resource Identities</strong></summary>

During a routine change, a teammate adds `Production` without noticing that `production` already exists. Because `for_each` keys are case-sensitive, Terraform treats them as two different resource identities. The plan keeps `aws_vpc.environment["production"]` and proposes creating another VPC at `aws_vpc.environment["Production"]`. The team catches the duplicate during plan review and does not apply it.

To prevent capitalization, surrounding spaces, and hyphens from producing inconsistent identities, the team decides to normalize all environment keys before supplying them to `for_each`. At the same time, a new QA environment arrives with the raw key `QA-environment `, but the project convention requires its identity to be `qa_environment`.

Start with the original `production` and `staging` entries still applied.

1. Declare local `clean_environments` using a map-producing `for` expression over `var.environments`.
   * Convert every key to lowercase.
   * Remove surrounding whitespace.
   * Replace hyphens with underscores.
   * Preserve the complete object associated with each key.
2. Change the VPC resource so its `for_each` uses `local.clean_environments`.
3. Output the normalized map as `normalized_environments` and add a description to the output.
4. Run `terraform plan` before adding another environment. Confirm that adopting the normalization layer does not change the existing VPCs because `production` and `staging` already follow the convention.
5. Add the new QA environment:

```hcl
"QA-environment " = {
  cidr     = "10.3.0.0/16"
  priority = 3
}
```

The quoted QA key contains uppercase letters, a hyphen, and one trailing space.

Run `terraform fmt`, `terraform validate`, and `terraform plan`. Do not apply the scenario plan.

Confirm that:

* The output contains `production`, `qa_environment`, and `staging`, even though the raw QA input uses `QA-environment `.
* Every normalized key remains paired with its original CIDR and priority.
* Terraform proposes creating only `aws_vpc.environment["qa_environment"]`.
* The existing `production` VPC remains unchanged.
* The existing `staging` VPC also remains unchanged.

<details>
<summary>Why the transformation does not create resources</summary>

`for_each` does not require a `for` expression; Parts 1–3 use the original map directly. A `for` expression is useful when input data must be transformed before another part of the configuration consumes it.

In this scenario, the `for` expression produces the normalized map, and the `locals` block gives that value the reusable name `clean_environments`. Neither operation creates a VPC. The resource-level `for_each` consumes that map and creates the separately addressed resource instances.

</details>

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. Why are `keys()`, `values()`, and `count.index` unnecessary in the main exercise?
2. What roles do `each.key` and `each.value` have?
3. Why does adding `development` not shift the production or staging addresses?
4. Does the normalization scenario's `for` expression create VPCs?
5. When is transforming a map before using `for_each` useful?
6. What can happen if two original keys normalize to the same result?

<details>
<summary>Review the answers</summary>

1. `for_each` consumes the map directly and preserves its keys as resource identities.
2. `each.key` provides the current environment name and identity; `each.value` provides its associated configuration object.
3. Each existing instance retains its own string-key address, so adding another key creates a separate address.
4. No. It transforms the example input map into another map value.
5. When input keys or values must be normalized, filtered, or otherwise reshaped before resource creation.
6. Terraform cannot construct a normal map with duplicate output keys unless the expression groups or otherwise resolves them.

</details>

## Cleanup

Restore the original two-element `environments` map, confirm a normal plan has no infrastructure changes, and run:

```bash
terraform destroy
terraform state list
```

Review the destroy plan before confirming it. The normalization scenario was not applied, so it creates no additional infrastructure to clean up.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* `for_each` accepts a map and creates resource instances addressed by its keys.
* `each.key` and `each.value` refer to the current map element.
* Adding one map key creates one new key-based resource address without shifting existing addresses.
* A `for` expression transforms a collection; it does not create resources.
* Local values give reusable names to expressions and cannot be overridden by callers.
* Normalize keys before initial resource creation when those normalized keys will become resource identities.

</details>
