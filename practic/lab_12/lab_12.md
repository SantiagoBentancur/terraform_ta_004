# Lab 12: Preconditions, Postconditions, and Check Blocks

## Objective

Your team stores an application-deployment record in Terraform. An unsupported environment must stop the operation before it proceeds, an invalid resulting record must fail its result validation, and an additional policy observation should report a warning without blocking the deployment.

In this lab, you will implement those three outcomes with a `precondition`, a `postcondition`, and a `check` block. A local `terraform_data` resource keeps the focus on when each condition is evaluated and whether its failure blocks Terraform, without creating cloud infrastructure.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Not started. Complete the requirements below before adding your solution.

**[View my Terraform solution](./lab_12.tf)**

When completed, this implementation should:

* Create one local record with no cloud cost.
* Block an invalid input before its associated operation.
* Validate a resulting object through `self`.
* Demonstrate that a failed `check` produces a warning rather than blocking the plan.

Validation commands:

```bash
terraform fmt -check
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Blocking operations with `precondition`
* Validating results with `postcondition`
* Referring to the current object with `self`
* Performing non-blocking validation with `check`
* Distinguishing errors from warnings
* Using `can()` and `regex()` safely

## Prerequisites

* Review [Custom Conditions](../../README.md#custom-conditions-precondition--postcondition) and [Check Blocks](../../README.md#check-blocks-and-continuous-validation).
* Use Terraform 1.5 or later.

This lab creates only a local `terraform_data` state record.

## Step-by-Step Requirements

Build the configuration in `lab_12.tf` in the order shown below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Build and Apply the Base Record</strong></summary>

<details>
<summary>Three validation outcomes</summary>

Terraform provides several validation boundaries:

* A `precondition` checks an assumption associated with an object before its operation proceeds.
* A `postcondition` checks the resulting object and can prevent dependent operations from continuing.
* A `check` observes infrastructure continuously during plans and applies but reports a warning when an assertion fails.

The `terraform_data` resource lets this lab demonstrate those behaviors without calling a cloud API.

</details>

1. Require Terraform 1.5 or later.
2. Declare:
   * `environment`, defaulting to `development`.
   * `owner_email`, defaulting to `platform@example.com`.
3. Define:
   * A local collection containing `development`, `staging`, and `production`.
   * A lowercase application name derived from the environment.
4. Create `terraform_data.application` whose input contains the name, environment, and owner.
5. Output the resulting application record.

Run:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Confirm that the output contains the expected lowercase application name, `development` environment, and owner email.

</details>

<details>
<summary><strong>Part 2: Add and Fail a Precondition</strong></summary>

6. Add a lifecycle precondition accepting only values from the allowed-environment collection.
7. Test it:

```bash
terraform plan -var='environment=qa'
```

Terraform should return an error and block the operation. Run a normal plan afterward.

Confirm that the error is your precondition message and that the previously applied state record remains unchanged.

</details>

<details>
<summary><strong>Part 3: Add and Fail a Postcondition</strong></summary>

8. Add a postcondition confirming that the resulting name is lowercase.
9. Inspect the result with `self.output.name`.
10. Temporarily change the normalized name to:

```hcl
normalized_name = "Customer-API-${var.environment}"
```

Run:

```bash
terraform plan
terraform apply
```

Terraform may defer evaluation until apply if the result is unknown during planning. A failed postcondition does not roll back a change that already occurred. Restore the lowercase expression and apply again.

Compare the plan-time and apply-time output carefully and record when Terraform has enough information to evaluate `self.output.name`.

</details>

<details>
<summary><strong>Part 4: Add and Fail a Check Block</strong></summary>

11. Add a `check` block that uses `can(regex(...))` to evaluate the email format.
12. Run:

```bash
terraform plan -var='owner_email=platform-team'
```

Terraform should report a warning and continue producing the plan. A check observes and reports; it does not block the operation.

Confirm that a complete plan summary is still produced after the warning. Restore the valid email before cleanup.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. Which mechanisms in this lab block an operation, and which one only warns?
2. Why does the postcondition use `self.output.name`?
3. Does a failed postcondition roll back a change already completed?
4. When might Terraform defer a condition until apply?
5. Why wrap `regex()` with `can()` in the check condition?
6. When would variable validation be a better location than a resource precondition?

<details>
<summary>Review the design questions and answers</summary>

1. Preconditions and postconditions can block; a failed check assertion reports a warning.
2. `self` inspects the resulting enclosing object without creating an invalid direct self-reference.
3. No. Terraform does not provide transactional rollback for a completed change.
4. Evaluation is deferred when a condition depends on a value that is unknown during planning.
5. `can()` converts a possible regex evaluation error into a boolean result the assertion can evaluate safely.
6. Use variable validation when the rule is intrinsic to acceptable input and does not depend on a particular resource operation.

The important skill is selecting the correct validation boundary and understanding whether failure blocks execution or only reports a warning.

</details>

## Cleanup

Restore valid values and run:

```bash
terraform destroy
```

Run `terraform state list` afterward and confirm that `terraform_data.application` is gone.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* Variable validation, lifecycle conditions, and checks operate at different scopes.
* Preconditions validate assumptions before an associated operation.
* Postconditions validate results and can stop dependent operations.
* Check blocks report warnings without blocking plans or applies.
* Conditions are evaluated during planning when their values are known.

</details>
