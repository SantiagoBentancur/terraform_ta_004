# Lab 1: Dynamic AMI Discovery

## Objective

Deploy one EC2 instance using an Amazon Linux 2023 AMI discovered at runtime. First, query and inspect an existing AMI through a data source. Then, use its ID to create a managed instance and expose useful results through outputs.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Not started. Complete the requirements below before adding your solution.

**[View my Terraform solution](./lab_1.tf)**

When completed, this implementation should:

* Configure AWS without embedding credentials.
* Select a current Amazon Linux 2023 AMI dynamically.
* Create one tagged EC2 instance from the selected AMI.
* Expose the selected AMI ID and created instance ID.

Validation commands:

```bash
terraform fmt -check
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Configuring a provider
* Declaring and referencing an input variable
* Reading existing information with a data source
* Creating infrastructure with a resource block
* Creating an implicit dependency through an attribute reference
* Exposing values with outputs

## Prerequisites

* Complete Lab 0.
* Review [Providers](../../README.md#providers), [Variables and Output Values](../../README.md#variables-and-output-values), [Data Sources](../../README.md#data-sources-data-blocks), and [Output Values](../../README.md#output-values).
* Configure AWS credentials outside Terraform with permission to create and terminate EC2 instances in `us-east-1`.

> **Cost Warning:** This lab creates an EC2 instance. Complete the cleanup procedure when finished.

## Step-by-Step Requirements

Build the configuration in `lab_1.tf` in the order shown below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Discover and Inspect the AMI</strong></summary>

<details>
<summary>Data source and resource overview</summary>

A data source reads information available through a provider. A managed resource asks the provider to create or manage an object. Reading an AMI does not make Terraform responsible for the AMI lifecycle.

When a resource argument references a data-source attribute, Terraform can determine that the lookup must finish before it configures the resource.

</details>

1. Configure the AWS provider to use `us-east-1`.
2. Declare a string variable named `environment`.
   * Add a useful description.
   * Default it to `development`.
3. Declare an `aws_ami` data source named `amazon_linux_2023`.
   * Select the most recent matching image.
   * Restrict the owner to Amazon.
   * Filter the name with `al2023-ami-2023.*-kernel-6.1-x86_64`.
   * Accept only images whose state is `available`.
4. Declare an output named `selected_ami_id` with a description.

Run:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

Confirm that Terraform reads one AMI and can determine `selected_ami_id`. It must not propose creating or owning the AMI.

</details>

<details>
<summary><strong>Part 2: Create and Test the EC2 Instance</strong></summary>

5. Create one `aws_instance` resource named `application`.
   * Use the ID returned by the AMI data source.
   * Use `t3.micro` as the instance type.
   * Add `Name`, `Environment`, and `ManagedBy` tags.
   * Build `Name` as `<environment>-application-server`.
6. Declare a described output named `instance_id` containing the instance ID.

Run:

```bash
terraform plan
```

Before applying, confirm:

* The plan proposes exactly one EC2 instance.
* Its AMI comes from the data-source reference rather than a copied AMI ID.
* The tags contain `development-application-server`, `development`, and `Terraform`.
* The summary reports `1 to add, 0 to change, 0 to destroy`.

After reviewing the complete plan, run:

```bash
terraform apply
terraform output
terraform state list
```

Confirm that state contains the EC2 resource but not a managed AMI resource.

</details>

<details>
<summary><strong>Part 3: Change the Input Without Editing the Default</strong></summary>

Preview a different environment through the CLI:

```bash
terraform plan -var='environment=staging'
```

Confirm that Terraform proposes changing the instance tags rather than creating a second instance. Do not apply this experiment. Run a normal plan afterward and expect no changes.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. What is the lifecycle difference between the AMI data source and the EC2 resource?
2. Why is selecting an AMI dynamically preferable to copying a temporary AMI ID?
3. What dependency is created by referencing the AMI ID from the instance?
4. Does changing `environment` create another Terraform instance address?
5. Which values are known during planning, and which may remain known only after apply?

<details>
<summary>Review the answers</summary>

1. The data source reads an existing AMI; the resource creates and manages the EC2 instance.
2. The filter can select a current matching image without manually updating a Region-specific identifier.
3. Terraform creates an implicit dependency from the EC2 resource to the AMI lookup.
4. No. The address remains `aws_instance.application`; only configured attributes change.
5. The selected AMI can normally be resolved during planning, while the new instance ID is assigned by AWS during apply.

</details>

## Cleanup

Run a normal plan first so cleanup uses the original default, then run:

```bash
terraform destroy
terraform state list
```

Review the destroy plan before confirming it. State should be empty afterward.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* A data source reads existing information but does not manage that object's lifecycle.
* A resource block manages infrastructure through a provider.
* Attribute references create implicit dependencies.
* Input variables parameterize configuration without duplicating resources.
* Outputs expose selected values from the root module.

</details>
