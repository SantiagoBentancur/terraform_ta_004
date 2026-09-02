# Lab 16: Sensitive, Ephemeral, and Write-Only Values

## Objective

Your team must rotate an application secret stored in AWS Systems Manager Parameter Store without persisting the plaintext value in Terraform's plan or state. Marking a value as sensitive only redacts its normal display, so it is not sufficient for this requirement.

In this lab, you will pass a disposable secret through a sensitive ephemeral input and send it to Parameter Store through a provider-supported write-only argument. A separate non-secret version value will signal rotation, allowing you to compare redaction with actual omission from stored Terraform data.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Not started. Complete the requirements below before adding your solution.

**[View my Terraform solution](./lab_16.tf)**

When completed, this implementation should:

* Accept a secret without persisting it in normal plan or state data.
* Send the value through a provider-supported write-only argument.
* Persist only a non-secret version signal used for rotation.
* Verify the difference between redaction and omission.

Validation commands:

```bash
terraform fmt -check
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Redacting display with `sensitive`
* Omitting values from plans and state with `ephemeral`
* Using a provider-supported write-only argument
* Triggering rotation with a non-secret version
* Supplying secrets without committed files
* Inspecting state without revealing the secret

## Prerequisites

* Review [Sensitive Input Variables and Outputs](../../README.md#sensitive-input-variables-and-outputs) and [Ephemeral Values and Write-Only Arguments](../../README.md#ephemeral-values-and-write-only-arguments).
* Use Terraform 1.11 or later.
* Configure AWS credentials with SSM Parameter Store permissions.

> **Security Warning:** Use a disposable value created only for this lab. Never reuse a real password or print it into shared terminal logs.

## Step-by-Step Requirements

Build the configuration in `lab_16.tf` in the order shown below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Build the Write-Only Secret Configuration</strong></summary>

<details>
<summary>Sensitive, ephemeral, and write-only overview</summary>

* `sensitive` redacts normal CLI presentation but does not by itself prevent state storage.
* `ephemeral` prevents Terraform from persisting the input in plan and state.
* A provider-supported write-only argument accepts a value without returning it to state.
* Adding `_wo` to an arbitrary argument does not make it write-only; the provider must implement it.

</details>

1. Require Terraform 1.11 or later and AWS provider 6.x.
2. Configure AWS for `us-east-1`.
3. Declare `parameter_value` as a required string with:
   * `sensitive = true`
   * `ephemeral = true`
4. Declare numeric `secret_version`, defaulting to `1`.
5. Validate that the version is a positive whole number.
6. Create an SSM `SecureString` parameter:
   * Pass the secret to `value_wo`.
   * Pass the version to `value_wo_version`.
7. Output only the parameter ARN and non-secret version.
8. Do not output the secret.

Run:

```bash
terraform fmt
terraform init
terraform validate
```

Before supplying a value, confirm that:

* The secret input has no committed default.
* The secret is both sensitive and ephemeral.
* Only the provider-supported write-only argument receives it.
* The output contains no secret value.

</details>

<details>
<summary><strong>Part 2: Supply, Plan, and Apply the Secret</strong></summary>

Read the value silently:

```bash
read -rsp "Temporary lab secret: " TF_VAR_parameter_value
export TF_VAR_parameter_value
echo
```

Then run:

```bash
terraform plan -out=secret.plan
terraform apply secret.plan
```

Terraform uses the ephemeral value during the operation but omits it from the saved plan and state.

Review the plan without attempting to decode or search for a real credential. Use only the disposable lab value and confirm that normal CLI output does not reveal it.

</details>

<details>
<summary><strong>Part 3: Inspect Stored Data</strong></summary>

Run:

```bash
terraform state show aws_ssm_parameter.secret
terraform show
```

You should see resource metadata and the non-secret write-only version, but not the `value_wo` input.

AWS Parameter Store, not Terraform state, retains the remote secret. Avoid retrieving and printing the decrypted value unless necessary.

Also inspect the saved plan with `terraform show secret.plan`. Confirm that metadata and the non-secret version may be present while the ephemeral write-only value is omitted.

</details>

<details>
<summary><strong>Part 4: Rotate the Secret</strong></summary>

Read a new disposable value:

```bash
read -rsp "Rotated temporary secret: " TF_VAR_parameter_value
export TF_VAR_parameter_value
echo
```

Increment the stored rotation counter:

```bash
terraform plan -var='secret_version=2'
terraform apply -var='secret_version=2'
```

Terraform cannot compare old and new secret values because neither is persisted. The normal version argument communicates rotation intent.

After applying, confirm that state contains the new non-secret version and still does not contain the secret value. A later plan with the same version should not signal another rotation merely because you re-enter the ephemeral input.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. Does `sensitive = true` guarantee that a value is absent from Terraform state?
2. What additional behavior does `ephemeral = true` provide?
3. Can you create a write-only argument by adding `_wo` to any provider argument name?
4. Why does the configuration need a normal, persisted version argument?
5. Where is the secret retained after a successful apply?
6. Does using ephemeral and write-only values eliminate the need to protect Terraform state?

<details>
<summary>Review the design questions and answers</summary>

1. No. Sensitive marking primarily controls presentation and propagation; ordinary sensitive values can still be stored in state.
2. Ephemeral values are omitted from plan and state persistence and are available only in permitted temporary contexts.
3. No. The provider schema must explicitly implement the write-only argument.
4. Terraform cannot compare an old secret that it never stored, so it needs a non-secret persisted signal to communicate rotation intent.
5. AWS Systems Manager Parameter Store retains the remote value; Terraform retains only relevant metadata and the non-secret version signal.
6. No. Other provider attributes, identifiers, outputs, and resources can still make state sensitive.

The goal is to distinguish hiding a value in the interface from preventing Terraform from persisting it.

</details>

## Cleanup

Keep `TF_VAR_parameter_value` available while Terraform evaluates the required input:

```bash
terraform destroy -var='secret_version=2'
unset TF_VAR_parameter_value
rm secret.plan
```

Omit the version override if you did not rotate.

Confirm that the SSM parameter is deleted, unset the environment variable, remove the saved plan, and run `terraform state list`.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* Sensitive values are usually stored in state even when redacted.
* Ephemeral values are omitted from plan and state.
* Managed-resource write-only arguments require Terraform 1.11+ and provider support.
* A write-only version argument provides a non-secret change trigger.
* Remote secret systems still require encryption and access controls.

</details>
