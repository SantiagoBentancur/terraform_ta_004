# Lab 11: Reusable VPC Module and EC2 Consumer

## Objective

Your platform team repeatedly creates the same VPC layout for application teams. Copying the network resources into every root configuration would make the design harder to reuse and maintain.

In this lab, you will move that network design behind a reusable child-module interface. A root module will provide the network settings, consume the resulting subnet and VPC outputs, and place an EC2 instance in a selected public subnet.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Not started. Complete the requirements below before adding your solution.

Root module:

* [main.tf](./main.tf)
* [variables.tf](./variables.tf)
* [outputs.tf](./outputs.tf)
* [terraform.tfvars](./terraform.tfvars)

Child network module:

* [main.tf](./modules/network/main.tf)
* [variables.tf](./modules/network/variables.tf)
* [outputs.tf](./modules/network/outputs.tf)

When completed, this implementation should:

* Define a reusable network module without embedded AWS configuration.
* Create stable public and private subnet instances from maps.
* Expose a small output interface to a root module.
* Place an EC2 consumer using a selected module output.

Validation commands:

```bash
terraform fmt -check -recursive
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Distinguishing root and child modules
* Declaring provider requirements in a child module
* Passing structured inputs
* Creating stable instances with `for_each`
* Exposing and consuming module outputs
* Inheriting the caller's default provider configuration
* Creating implicit dependencies across module boundaries

## Prerequisites

* Review [Terraform Modules](../../README.md#terraform-modules), [Module Sources](../../README.md#module-sources), and [The Provider Rule](../../README.md#the-provider-rule-exam-trap).
* Configure AWS credentials with VPC, subnet, route-table, security-group, and EC2 permissions.

> **Cost Warning:** This lab creates an EC2 instance. Run the cleanup procedure when finished.

## Project Structure

```text
lab_11/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── lab_11.md
└── modules/
    └── network/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Step-by-Step Requirements

Build the files shown above in the order below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Build and Validate the Child Network Module</strong></summary>

<details>
<summary>Reusable module boundary</summary>

The root module represents the application deployment and owns the concrete AWS configuration. The child module owns the reusable network design and exposes only the values its callers need.

The working directory containing the main configuration is the root module. A module called through a `module` block is a child module. Reusable child modules declare provider requirements but receive provider configurations from their callers.

</details>

1. In `modules/network/`, declare the AWS provider requirement without adding a `provider "aws"` configuration.
2. Declare inputs:
   * `project_name`
   * `environment`
   * `vpc_cidr`
   * `public_subnets` as a map of objects containing `cidr` and `availability_zone`
   * `private_subnets` with the same type
3. Create:
   * One VPC and Internet Gateway.
   * Public and private subnets using `for_each`.
   * One public route table with an Internet Gateway route.
   * One isolated private route table without an internet route.
   * Associations for every subnet.
4. Enable public-IP assignment only on public subnets.
5. Output:
   * `vpc_id`
   * `public_subnet_ids` as a map keyed by input names
   * `private_subnet_ids` with the same pattern

The module intentionally has no NAT Gateway; private subnets have no outbound internet path.

Format the child module before continuing:

```bash
terraform fmt -recursive
```

At this point, do not run the child directory as an independent deployment. It is designed to receive input values and a provider configuration from a caller.

</details>

<details>
<summary><strong>Part 2: Call and Test the Network Module</strong></summary>

6. In the root module:
   * Declare the root variables in `variables.tf`.
   * Configure the AWS provider in `main.tf`.
   * Call the module with `source = "./modules/network"`.
   * Pass two public and two private subnet definitions across two Availability Zones.
7. Expose the module's VPC ID and both subnet maps through root outputs.

Run:

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
```

Inspect addresses such as:

```text
module.network.aws_subnet.public["public_a"]
module.network.aws_subnet.private["private_b"]
```

Before applying, confirm:

* The plan contains one VPC, one Internet Gateway, two public subnets, and two private subnets.
* Each subnet address uses its map key rather than a numeric index.
* Only the public route table has a default route to the Internet Gateway.
* The child module contains a provider requirement but no configured `provider "aws"` block.

</details>

<details>
<summary><strong>Part 3: Add and Deploy the EC2 Consumer</strong></summary>

8. Discover the latest Amazon Linux 2023 AMI.
9. Create a security group in `module.network.vpc_id`.
10. Use standalone security-group rule resources to allow:
    * HTTP on port 80 from `0.0.0.0/0`.
    * Outbound IPv4 traffic.
    * Do not open SSH.
11. Create one EC2 instance:
    * Use `var.instance_type`.
    * Select its subnet with:

      ```hcl
      subnet_id = module.network.public_subnet_ids[var.ec2_subnet_key]
      ```

    * Assign a public IPv4 address.
    * Use user data to install and start Nginx.
12. Output the instance ID and application URL.

Run:

```bash
terraform plan
terraform apply
terraform output
```

Open the application URL after cloud-init finishes.

Confirm that the EC2 instance is in the selected public subnet and that references to `module.network.vpc_id` and `module.network.public_subnet_ids[...]` create the required dependency automatically.

</details>

<details>
<summary><strong>Part 4: Change a Consumed Module Output</strong></summary>

Change `ec2_subnet_key` from `public_a` to `public_b`, then run:

```bash
terraform plan
```

Moving an existing EC2 instance to another subnet requires replacement. Do not apply unless you intend to replace it. Restore the original key.

Inspect the attribute marked as forcing replacement and confirm that the VPC and subnet resources themselves are not being recreated.

</details>

<details>
<summary><strong>Part 5: Extend a Module Input</strong></summary>

Add one subnet object with a unique CIDR and valid Availability Zone, then run `terraform plan`.

Terraform should add one keyed subnet and one association without shifting existing addresses. Remove the experimental subnet before cleanup.

Run another plan after removing it and confirm the configuration has returned to the previously applied shape.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. What is the difference between the root module and the child network module?
2. Why can the EC2 resource wait for the module resources without an explicit `depends_on`?
3. Can the root module access `module.network.aws_vpc.this.id` directly?
4. Why should the child module declare a provider requirement but avoid configuring credentials or a Region?
5. Why are maps preferable to lists for keyed subnet instances?
6. What Terraform command must be rerun after adding or changing a module source?

<details>
<summary>Review the design questions and answers</summary>

1. The root module is the working configuration Terraform executes; the child module is called and receives inputs from it.
2. References to module outputs create implicit dependency edges.
3. No. The caller can consume only values exposed through child-module outputs.
4. The caller should control credentials, Region, aliases, and execution context while the child declares which plugin it needs.
5. Map keys give each subnet a meaningful, stable address that does not shift when another element is added or removed.
6. Run `terraform init` so Terraform installs or refreshes the module source.

The module is successful when it provides a clear reusable interface, not merely when its resources have been moved into another directory.

</details>

## Cleanup

Restore the original inputs, review the destroy plan, and run:

```bash
terraform destroy
```

Confirm that the instance and security-group rules are removed before the network dependencies, then run `terraform state list`.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* Every configuration has a root module.
* Local module sources begin with `./` or `../`.
* Child modules declare provider requirements but receive configurations from callers.
* Outputs form the public interface of a child module.
* Module input and output references create implicit dependencies.
* Run `terraform init` after adding or changing a module source.

</details>
