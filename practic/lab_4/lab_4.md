# Lab 4: Understanding `count` with Map-Based Resources

## Objective

Compare the position-based identity created by `count` with the key-based identity of a map. First, use `count.index` with `keys()` and `values()` to connect each VPC to its environment object. Then, insert another environment and observe how the ordered positions—and therefore the data associated with numeric resource addresses such as `[0]` and `[1]`—shift. This lab focuses on how `count` assigns identity by numeric position; Lab 5 rebuilds the same scenario with `for_each`, which assigns identity using the environment keys.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Completed.

**[View my Terraform solution](./lab_4.tf)**

When completed, this implementation should:

* Accept VPC definitions through a `map(object(...))` whose objects combine different attribute types.
* Connect that map to numeric instances with `keys()`, `values()`, and `count`.
* Preserve the pairing between each ordered key and value.
* Demonstrate the effect of position-based identities when the map changes.

Validation commands:

```bash
terraform fmt -check
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Declaring a `map(object(...))` variable
* Combining `string` and `number` attributes in one object
* Calculating instance count with `length()`
* Reading alphabetically ordered map keys with `keys()`
* Reading values in the corresponding order with `values()`
* Addressing resource instances by numeric index
* Distinguishing data identity from collection position

## Prerequisites

* Complete Labs 1–3.
* Review [Complex Data Types](../../README.md#complex-data-types-object-and-set), [Collection Functions](../../README.md#collection-functions), [String and Conversion Functions](../../README.md#string-and-conversion-functions), and [`count`](../../README.md#the-count-meta-argument).
* Configure AWS credentials with permission to create and delete VPCs.

> **Cleanup Warning:** This lab creates VPCs. Do not add subnets or other dependent objects outside Terraform while performing the exercise.

## Step-by-Step Requirements

Build the configuration in `lab_4.tf` in the order shown below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Build and Apply the Count-Based VPCs</strong></summary>

<details>
<summary>How a map becomes count-based resource instances</summary>

`keys()` and `values()` are built-in Terraform collection functions, not terminal commands. The map in this lab identifies each environment by name, but `count` identifies resource instances by number. These functions let Terraform present the map as two corresponding ordered lists:

```text
keys(var.environments)   -> ["production", "staging"]
values(var.environments) -> [production object, staging object]
```

`count.index` selects the same position from both lists:

| `count.index` | Environment key | CIDR | Priority | Resource address |
|---:|---|---|---:|---|
| `0` | `production` | `10.2.0.0/16` | `1` | `aws_vpc.environment[0]` |
| `1` | `staging` | `10.1.0.0/16` | `2` | `aws_vpc.environment[1]` |

Using the same index for `keys()` and `values()` keeps each name paired with the correct CIDR. However, `[0]` means only “the first item”; it does not permanently mean `production`. If a new key sorts before `production`, the data at `[0]` changes. Part 2 demonstrates the resulting problem.

</details>

1. Configure AWS for `us-east-1`.
2. Declare `environments` as a map of objects containing:
   * `cidr` as a string.
   * `priority` as a number.
3. Define:
   * `staging` with CIDR `10.1.0.0/16` and priority `2`.
   * `production` with CIDR `10.2.0.0/16` and priority `1`.
4. Create `aws_vpc.environment`.
   * Set `count` from the map length.
   * Select each CIDR from the ordered values using the current index.
   * Set `instance_tenancy` to `default`.
   * Add the following tags:
     * `Name`: prefix the current environment name with `vpc-`.
     * `Environment`: select the current environment name using `keys(var.environments)[count.index]`.
     * `Priority`: select the object's numeric priority and convert it to a string with `tostring()`.
     * `ManagedBy`: set it to `Terraform`.

Run:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

Confirm that:

* `keys(var.environments)` effectively orders `production` before `staging`.
* Address `[0]` receives the production data.
* Address `[1]` receives the staging data.
* Each `Priority` tag contains the string form of the corresponding numeric priority.
* The plan proposes exactly two VPCs.

Apply and inspect:

```bash
terraform apply
terraform state list
terraform state show 'aws_vpc.environment[0]'
terraform state show 'aws_vpc.environment[1]'
```

</details>

<details>
<summary><strong>Part 2: Insert a Key and Observe Index Shifting</strong></summary>

Temporarily add this map element:

```hcl
development = {
  cidr     = "10.0.0.0/16"
  priority = 3
}
```

Run `terraform plan` but do not apply it.

Because `development` sorts before `production` and `staging`, inspect how the data associated with indexes `[0]` and `[1]` changes and how a new `[2]` appears. Identify which arguments Terraform can update and which would require replacement.

Restore the original two-element map and run another plan. It should return to no changes.

</details>

<details>
<summary><strong>Part 3: Compare Numeric and Key-Based Addresses</strong></summary>

This is a comparison exercise only. Do not change `lab_4.tf` and do not run another apply.

The resources created with `count` currently use numeric addresses:

```text
aws_vpc.environment[0] -> production
aws_vpc.environment[1] -> staging
```

Now imagine that the environment names were used as the resource identities instead:

```text
aws_vpc.environment["production"]
aws_vpc.environment["staging"]
```

These quoted-key addresses are hypothetical in this lab; they are not present in the current state.

Based on what happened in Part 2, answer:

1. If `development` were added, which new key-based address would appear?
2. Would the addresses for `production` and `staging` need to change?
3. Which address style tells you the environment identity without inspecting the resource?

Lab 5 implements the key-based version with `for_each`.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. Why must `keys()` and `values()` use the same index?
2. What determines the ordering returned by `keys()` for a map?
3. Does `aws_vpc.environment[0]` mean production permanently?
4. Why can inserting one key affect more than one existing instance?
5. Is using `count` invalid here, or merely less suitable for this identity model?
6. Why can each environment object contain both a CIDR string and a numeric priority?
7. Why is `tostring()` used when assigning the priority to a tag?

<details>
<summary>Review the answers</summary>

1. Their ordering corresponds, so using the same index keeps an environment name paired with its CIDR.
2. Terraform returns the map keys in alphabetical order.
3. No. It means the item currently occupying numeric position zero.
4. The insertion changes the ordered positions associated with existing numeric addresses.
5. It is valid Terraform, but map keys represent these VPC identities more safely and clearly.
6. An object has its own schema, and each named attribute can have a different declared type.
7. The priority is a number in the object, while AWS tag values are strings.

</details>

## Cleanup

Restore the original map, verify a normal plan has no changes, and run:

```bash
terraform destroy
terraform state list
```

Review the destroy plan before confirming it.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* `keys()` returns map keys in alphabetical order.
* `values()` follows the corresponding key order.
* An object can combine named attributes of different types, such as `string` and `number`.
* `count` creates numeric instance addresses.
* Position-based identities can shift when an ordered input changes.
* Choose `for_each` when meaningful stable keys represent resource identity.

</details>
