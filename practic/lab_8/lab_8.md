# Lab 8: Variable Validation, Preconditions, and IAM Users

## Objective

Your platform team receives onboarding requests containing a team name and a list of developers. For each request, Terraform must create one IAM user per developer without silently accepting malformed or inconsistent data.

Begin by modeling the request as one structured input and creating the IAM users from valid data. Once that workflow works, add safeguards at three different boundaries: a type constraint for the required structure, variable validation for rules that every request must satisfy, and a resource precondition for an assumption made by the IAM user configuration. Finish by transforming the created resource instances into a username-to-ARN output map.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Completed.

**[View my Terraform solution](./lab_8.tf)**

When completed, this implementation should:

* Accept a team name and developer names through one structured object.
* Reject invalid team names and duplicate developers before creating resources.
* Create stable IAM user instances with `for_each`.
* Enforce a team-size assumption with a resource precondition.
* Return the created usernames and ARNs as a map.

Validation commands:

```bash
terraform fmt -check
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Declaring an `object` containing a `list(string)`
* Distinguishing type constraints from custom validation
* Writing multiple input-variable validation rules
* Comparing collection sizes with `length()` and `toset()`
* Creating stable resource instances with `for_each`
* Reading `each.key` and `each.value`
* Enforcing an assumption with a lifecycle `precondition`
* Transforming resource instances with a `for` expression

## Prerequisites

* Review [Input Variable Validation](../../README.md#input-variable-validation), [Custom Conditions](../../README.md#custom-conditions-precondition--postcondition), [`for_each` vs. `count`](../../README.md#advanced-looping-for_each-vs-count), and [`for` Expressions](../../README.md#for-expressions).
* Configure AWS credentials with permission to create, tag, and delete IAM users.

> **Security and Cleanup Warning:** This lab creates IAM identities in the AWS account. It does not create login profiles, access keys, or policy attachments, so the users receive no permissions from this lab. Review the plan carefully and destroy the users when you finish.

## Step-by-Step Requirements

Build the configuration in `lab_8.tf` in the order shown below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Build and Test the Team Resources</strong></summary>

<details>
<summary>Team onboarding scenario</summary>

An onboarding request contains two related pieces of information: the name of the team and the developers who belong to it. Representing them as attributes of one object keeps the complete request together while still enforcing a known structure.

The request initially stores the developer names in a list. Before using that collection with `for_each`, you will convert it to a set so that every developer name becomes a resource key:

```text
team_config object
  -> developers list
  -> set of developer names
  -> one IAM user instance per name
```

Terraform can then address the instances by developer name instead of by a numeric position:

```text
aws_iam_user.team["alice"]
aws_iam_user.team["bob"]
aws_iam_user.team["charlie"]
```

These keys preserve the identity of unaffected users when the team membership changes. The IAM username itself will combine the team name with the developer name.

After the valid resources work, later parts of the lab will test several bad onboarding requests. Each failure will demonstrate which kind of Terraform safeguard is responsible for rejecting it.

</details>

1. Configure the AWS provider to use `us-east-1`.
2. Declare an input variable named `team_config`.
3. Give the variable an object type containing:
   * `team_name` as a string.
   * `developers` as a `list(string)`.
4. Use this initial default value:

   ```hcl
   default = {
     team_name  = "dev-backend"
     developers = ["alice", "bob", "charlie"]
   }
   ```

5. Create an `aws_iam_user` resource named `team`.
   * Create one instance for every developer.
   * Convert the developer list to the collection type required by `for_each`.
   * Use the current developer name as part of the final IAM username.
   * The final username format must be `<team_name>-<developer>`.
   * Add a `Team` tag containing the team name.
   * Add a `ManagedBy` tag containing `Terraform`.
6. Declare an output named `developer_arns`.
   * Return a map whose keys are the final IAM usernames.
   * Set each value to the corresponding IAM user ARN.

Test Part 1 before continuing:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

Review the plan and confirm:

* Terraform proposes exactly three IAM users.
* Their resource addresses use the developer names as `for_each` keys.
* Their AWS names are `dev-backend-alice`, `dev-backend-bob`, and `dev-backend-charlie`.
* Every user has both required tags.
* The summary reports `3 to add, 0 to change, 0 to destroy`.

After verifying the complete plan, run:

```bash
terraform apply
terraform output developer_arns
```

Confirm that the output is a map containing three final IAM usernames and three ARNs.

</details>

<details>
<summary><strong>Part 2: Add and Test Input Validation</strong></summary>

The type constraint from Part 1 verifies the shape of the value, but it does not yet enforce the rules of this lab. A correctly typed team could still have an unacceptable prefix or repeated developer names.

7. Add a validation rule to `team_config` requiring `team_name` to begin with `dev-`.
   * The condition must evaluate the `team_name` attribute of the object.
   * Provide an error message that clearly explains the required prefix.
8. Add a separate validation rule that rejects duplicate developer names.
   * Do not hardcode the expected number of developers.
   * Compare the number of elements in the original list with the number remaining after converting it to a set.
   * Provide an error message explaining that developer names must be unique.

Test the prefix rule by temporarily changing:

```hcl
team_name = "ops-backend"
```

Run:

```bash
terraform plan
```

Confirm that Terraform reports your prefix-validation message before proposing infrastructure changes. Restore `dev-backend` afterward.

Next, test duplicate detection with:

```hcl
developers = ["alice", "bob", "alice"]
```

Run `terraform plan` again and confirm that Terraform reports your uniqueness-validation message. Restore the original developer list before continuing.

Notice the reason for testing this explicitly: converting the list to a set for `for_each` would silently collapse repeated values. Validation turns that hidden data loss into a visible input error.

</details>

<details>
<summary><strong>Part 3: Add and Test a Resource Precondition</strong></summary>

9. Add a lifecycle precondition to `aws_iam_user.team`.
   * Require the team configuration to contain at least two developers.
   * Provide an error message explaining the minimum team size.
10. Temporarily change the developer list to:

```hcl
developers = ["alice"]
```

Run:

```bash
terraform plan
```

Confirm that:

* The value satisfies the declared object type.
* The developer list contains no duplicate names.
* The variable validation rules pass.
* The resource precondition rejects the one-person team.

Restore the original developer list before continuing.

This separation is intentional. The validation rules define acceptable input data, while the precondition protects an assumption made by the resource configuration.

> **Important `for_each` Limitation:** This precondition is evaluated on each IAM user instance that `for_each` creates. A one-developer list creates one instance, so the precondition runs and rejects it. An empty list creates no instances, so there is no resource instance on which Terraform can evaluate this precondition. If the configuration must reject an empty developer list reliably, enforce the minimum size with input-variable validation or with a separate validation object that always exists.

</details>

<details>
<summary><strong>Part 4: Trigger and Compare a Type Error</strong></summary>

11. Temporarily assign a string instead of a list:

```hcl
developers = "alice"
```

Run:

```bash
terraform plan
```

Terraform should reject the value because it does not match `list(string)`. Compare this diagnostic with the custom messages produced in Parts 2 and 3.

Confirm that the failure happens at the type boundary: Terraform cannot treat the value as a valid `team_config`, so it does not need the custom validation rule or resource precondition to identify the problem.

Restore the valid default value afterward and run:

```bash
terraform fmt
terraform validate
terraform plan
```

The final plan should contain no infrastructure changes if the valid configuration from Part 1 is still applied.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. Why is duplicate validation necessary when `for_each` already receives `toset(var.team_config.developers)`?
2. What is the difference between a type constraint, variable validation, and a resource precondition in this lab?
3. Why are developer names better instance keys than numeric list indexes for these IAM users?
4. Does the output `for` expression create or modify any IAM users?
5. What change would Terraform propose if you removed `bob` from the valid developer list?
6. Should the `dev-` prefix rule be implemented as a variable validation or as a resource precondition? Why?
7. Why would the resource precondition fail to reject an empty developer list?

<details>
<summary>Review the answers</summary>

1. `toset()` silently removes duplicate values. The validation reports the input mistake instead of quietly creating fewer users than the caller supplied.
2. The type constraint defines the required data shape, variable validation rejects correctly typed but unacceptable input, and the precondition blocks the resource operation when a resource-related assumption is false.
3. String keys preserve the identity of unaffected developers. Removing one name does not shift numeric addresses belonging to the remaining users.
4. No. A `for` expression transforms values to build the output map; it does not create resource instances.
5. Terraform should propose destroying only `aws_iam_user.team["bob"]`, while the instances keyed by `alice` and `charlie` remain unchanged.
6. It belongs in variable validation because it is an intrinsic rule for acceptable `team_config.team_name` input and can be rejected before evaluating the resource configuration.
7. An empty collection produces zero `for_each` instances, so Terraform has no IAM user instance on which to evaluate the lifecycle precondition.

The purpose of the lab is not merely to collect several validation features. It is to place each rule at the correct boundary and preserve clear, stable resource identities.

</details>

## Cleanup

Restore the valid defaults first and run:

```bash
terraform plan
```

Confirm that the working configuration is valid and that Terraform is not planning an unintended replacement or deletion. Then run:

```bash
terraform destroy
```

Review the complete destroy plan before confirming it. Terraform should delete the three IAM users created by this lab. Afterward, run `terraform state list` and confirm that no managed IAM user instances remain.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* A type constraint defines the structural type Terraform accepts for an input variable.
* Variable validation evaluates additional rules for values that satisfy the type constraint.
* Multiple validation blocks can report separate requirements with specific error messages.
* `for_each` accepts a map or a set of strings and creates separately addressed resource instances.
* Converting a list to a set removes duplicates, which can hide invalid input unless it is validated first.
* A lifecycle `precondition` blocks an operation when an assumption required by the resource is false.
* A resource precondition is not evaluated when `for_each` creates zero instances; collection-wide minimum-size rules belong in variable validation or another object that always exists.
* A `for` expression transforms a collection into another value without creating resources.

</details>
