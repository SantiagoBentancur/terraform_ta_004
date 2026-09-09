# Lab 11: Reusable VPC Module and EC2 Consumer

## Objective

Your platform team repeatedly creates the same VPC layout for application teams. Copying the network resources into every root configuration would make the design harder to reuse and maintain.

In this lab, you will move that network design behind a reusable child-module interface. A root module will provide the network settings, consume the resulting subnet and VPC outputs, and place an EC2 instance in a selected public subnet.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Completed.

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
        ├── README.md
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

`modules/network/README.md` documents the child module's public interface: its input names, Terraform types, default values, required subnet maps, outputs, and provider-configuration boundary. Use it as the reference while declaring the variables and outputs in the module.

## Step-by-Step Requirements

Build the files shown above in the order below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Build and Validate the Child Network Module</strong></summary>

<details>
<summary>Reusable module boundary</summary>

The root module represents the application deployment and owns the concrete AWS configuration. The child module owns the reusable network design and exposes only the values its callers need.

The working directory containing the main configuration is the root module. A module called through a `module` block is a child module. Reusable child modules declare provider requirements but receive provider configurations from their callers.

</details>

1. In `modules/network/main.tf`, declare the AWS provider requirement without adding a `provider "aws"` configuration:

   ```hcl
   terraform {
     required_providers {
       aws = {
         source = "hashicorp/aws"
       }
     }
   }
   ```

   The child module declares which provider it needs, while the root module later supplies the configured provider. Do not add credentials or a Region in the child module.
2. In `modules/network/variables.tf`, declare the five input variables described in the [network module input contract](./modules/network/README.md#input-contract):
   * `project_name` as a `string` with default `"lab_11"`.
   * `environment` as a `string` with default `"dev"`.
   * `vpc_cidr` as a `string` with default `"10.0.0.0/24"`.
   * `public_subnets` as a required `map(object({ cidr = string, availability_zone = string }))`.
   * `private_subnets` as a required map with the same object type.

   The two subnet maps have no defaults because the caller must provide the actual subnet layout. Keep the Terraform types in `variables.tf` aligned with the documented interface.

   > **Pause and think:** Are these variables inputs to the child module or outputs from it? Which configuration supplies their values, and where would you look for values leaving the module?
   >
   > **Key idea:** The `variable` blocks define the child module's inputs. The root module supplies those values in its `module "network"` block. The child module's `output` blocks define the values that the root module can consume through references such as `module.network.vpc_id`.

3. Create:
   * One VPC using `cidr_block = var.vpc_cidr` and one Internet Gateway.
   * Public and private subnets using `for_each`. The child module should read each object's `cidr` and `availability_zone` attributes; the root module supplies the actual values in Part 2.
   * One public route table associated with the public subnets. Add a `0.0.0.0/0` route from that table to the Internet Gateway so those subnets have a path to the internet.
   * One private route table associated with the private subnets. Do not add an internet route or NAT Gateway; those subnets intentionally have no outbound internet path in this lab.
   * Associations for every subnet.
4. Enable public-IP assignment only on public subnets.
5. Output:
   * `vpc_id`
   * `public_subnet_ids` as a map keyed by input names
   * `private_subnet_ids` with the same pattern

   > **Hint:** Because the subnet resources use `for_each`, `aws_subnet.public_subnets` and `aws_subnet.private_subnets` are maps of resource instances rather than single objects. Use a map-producing `for` expression in each output: keep the instance key and return that instance's `.id` as the value. Make sure the private output iterates over the private subnet resource collection.

The route table is not a label that automatically makes a subnet public or private: the subnet's association and routes determine its path. In this lab, a subnet is considered public because it is associated with the table whose default route points to the Internet Gateway. A private subnet is associated with the table that has no such route. The module intentionally has no NAT Gateway, so private subnets cannot reach the internet from this design.

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
   * Pass two public and two private subnet definitions across two Availability Zones. Use the following CIDRs inside the default `10.0.0.0/24` VPC:

     ```hcl
     public_subnets = {
       public_a = {
         cidr              = "10.0.0.0/26"
         availability_zone = "us-east-1a"
       }
       public_b = {
         cidr              = "10.0.0.64/26"
         availability_zone = "us-east-1b"
       }
     }

     private_subnets = {
       private_a = {
         cidr              = "10.0.0.128/26"
         availability_zone = "us-east-1a"
       }
       private_b = {
         cidr              = "10.0.0.192/26"
         availability_zone = "us-east-1b"
       }
     }
     ```

     These values belong in the root module's input configuration, such as `terraform.tfvars`; the child module receives them through its `module "network"` block.
7. Expose the module's values through root outputs named `vpc_id`, `public_subnet_ids`, and `private_subnet_ids`.

Run:

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
```

Inspect addresses such as:

```text
module.network.aws_subnet.public_subnets["public_a"]
module.network.aws_subnet.private_subnets["private_b"]
```

Before applying, confirm:

* The plan contains one VPC, one Internet Gateway, two public subnets, and two private subnets.
* The plan contains one public route table, one private route table, and one association for each subnet.
* Each subnet address uses its map key rather than a numeric index.
* Only the public route table has a default route to the Internet Gateway.
* The child module contains a provider requirement but no configured `provider "aws"` block.

</details>

<details>
<summary><strong>Part 3: Add and Deploy the EC2 Consumer</strong></summary>

8. Discover the latest Amazon Linux 2023 AMI.
9. In the root module, create a security group for the EC2 instance. Set its `vpc_id` argument to `module.network.vpc_id`, the VPC ID exposed by the child network module.
10. Use standalone security-group rule resources to allow:
    * Outbound IPv4 traffic.
    * Do not open SSH or HTTP; this lab does not deploy an application service.
11. Create one EC2 instance:
    * Declare `selected_public_subnet_key` as a string input with a default of `"public_a"`. Its value must match one of the keys in `public_subnets`.
    * Use `var.instance_type`.
    * Select its subnet with:

      ```hcl
      subnet_id = module.network.public_subnet_ids[var.selected_public_subnet_key]
      ```

      With the default value, Terraform evaluates this as `module.network.public_subnet_ids["public_a"]`. Changing the variable to `"public_b"` selects the other public subnet.

    * Assign a public IPv4 address.
12. Output:
    * `instance_id`
    * `instance_public_ip`

Run:

```bash
terraform plan
terraform apply
terraform output
```

Inspect the instance ID and public IP outputs. No application endpoint is expected because this lab creates only the EC2 consumer, not an application service.

Confirm that the EC2 instance is in the selected public subnet and that references to `module.network.vpc_id` and `module.network.public_subnet_ids[...]` create the required dependency automatically.

</details>

<details>
<summary><strong>Part 4: Change a Consumed Module Output</strong></summary>

Change `selected_public_subnet_key` from `public_a` to `public_b`, then run:

```bash
terraform plan
```

Moving an existing EC2 instance to another subnet requires replacement. Do not apply unless you intend to replace it. Restore the original key.

Inspect the attribute marked as forcing replacement and confirm that the VPC and subnet resources themselves are not being recreated.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. What is the difference between the root module and the child network module?
2. Why can the EC2 resource wait for the module resources without an explicit `depends_on`?
3. Can the root module access `module.network.aws_vpc.main.id` directly?
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
