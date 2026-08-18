# Lab 3: Conditional Infrastructure

## Objective

Change the number and size of EC2 instances through one Boolean input. First, deploy the development configuration. Then, preview the production configuration and analyze how conditional expressions affect count, instance type, tags, and resource addresses.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Completed.

**[View my Terraform solution](./lab_3.tf)**

When completed, this implementation should:

* Select development or production behavior from a Boolean input.
* Look up an instance type using the string form of that Boolean.
* Create one or two EC2 instances conditionally.
* Demonstrate how changing inputs changes an existing desired configuration.

Validation commands:

```bash
terraform fmt -check
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Declaring a Boolean input variable
* Selecting values with conditional expressions
* Converting values with `tostring()`
* Looking up a value in a typed map
* Setting `count` conditionally
* Using `count.index` in tags

## Prerequisites

* Complete Labs 1 and 2.
* Review [Conditional Expressions](../../README.md#conditional-expressions), [String and Conversion Functions](../../README.md#string-and-conversion-functions), and [`count`](../../README.md#the-count-meta-argument).
* Configure AWS credentials with permission to create and terminate EC2 instances.

> **Cost Warning:** This lab creates one EC2 instance by default and can create two in production mode. Complete cleanup using the same input values as the applied configuration.

## Step-by-Step Requirements

Build the configuration in `lab_3.tf` in the order shown below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Build and Apply the Development Configuration</strong></summary>

<details>
<summary>Conditional values and conditional instances</summary>

A conditional expression selects one of two values. When used for an argument such as `instance_type`, it changes an attribute. When used to calculate `count`, it changes how many resource instances exist and therefore changes the set of state addresses.

</details>

1. Configure AWS for `us-east-1`.
2. Declare Boolean `is_production`, defaulting to `false`.
3. Declare `instance_types` as `map(string)` with:
   * String key `true` mapped to `t3.small`.
   * String key `false` mapped to `t3.micro`.
4. Discover Amazon Linux 2023 with the owner and filters used in Lab 1.
5. Create an EC2 resource block with resource type `aws_instance` and local name `environment_server`. Its declaration should begin with `resource "aws_instance" "environment_server"`.
   * Use a conditional expression to create two instances in production and one otherwise.
   * Select the instance type by converting the Boolean to the map's string key.
   * Add `Name`, `Environment`, and `ManagedBy` tags.
   * Use `prod` or `dev` plus `count.index` in `Name`.
   * Use `production` or `development` in `Environment`.

Run:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

Confirm that the default plan proposes one `t3.micro` instance at `aws_instance.environment_server[0]` with development tags. Apply it and inspect `terraform state list`.

</details>

<details>
<summary><strong>Part 2: Preview Production Behavior</strong></summary>

Run without editing the default:

```bash
terraform plan -var='is_production=true'
```

Confirm that the desired production configuration contains:

* Two instances at indexes `[0]` and `[1]`.
* `t3.small` as the selected type.
* Production names and environment tags.
* A proposed new instance at `[1]`.
* A proposed change to the existing `[0]` instance.

Look at the action symbol shown for `aws_instance.environment_server[0]`. Determine whether Terraform proposes an in-place update (`~`) or a replacement (`-/+`). The AWS provider decides this based on which arguments changed; a changed value does not automatically mean replacement. Record what the plan shows, but do not apply the production plan.

Run a normal `terraform plan` afterward and expect no changes.

</details>

<details>
<summary><strong>Part 3: Trigger and Compare an Input Type Error</strong></summary>

Run:

```bash
terraform plan -var='is_production=not-a-boolean'
```

Confirm that Terraform rejects the value at the Boolean type boundary before it can evaluate the production behavior. Finish with another normal plan.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. Why is `tostring()` required before using the Boolean as a map key?
2. What changes when the conditional expression is used for `count`?
3. Does production mode create a new independent resource block?
4. Why does instance `[0]` keep the same Terraform address in both modes?
5. Could a direct conditional select the instance type without a map?

<details>
<summary>Review the answers</summary>

1. The map keys are strings, while `is_production` is a Boolean value.
2. It changes the number of separately addressed instances in the desired configuration.
3. No. Both modes use instances of the same `aws_instance.environment_server` block.
4. Count addresses instances by numeric position, and position zero exists in both configurations.
5. Yes. The map is intentionally used here to practice typed lookup and conversion.

</details>

## Cleanup

Because only the default development configuration was applied, run:

```bash
terraform destroy
terraform state list
```

If you chose to apply production mode, pass `-var='is_production=true'` during destroy. Review the plan before confirming.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* A conditional expression selects between two values of compatible types.
* Input type constraints reject incompatible CLI values.
* `tostring()` performs explicit value conversion.
* Conditional `count` changes how many resource instances exist.
* A changed provider argument may update in place or force replacement depending on its schema and context.

</details>
