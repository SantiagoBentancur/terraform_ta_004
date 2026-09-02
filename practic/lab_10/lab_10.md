# Lab 10: Provisioners and Connections

## Objective

A legacy EC2 deployment requires a command to run on the Terraform operator's machine and a temporary SSH-based bootstrap process to install Nginx on the instance. The team also needs to understand what happens when one of those commands fails or the instance is destroyed.

Use this controlled scenario to compare local and remote execution, SSH connections, creation-time and destroy-time behavior, and `on_failure = continue`. Provisioners appear in Terraform and certification material, but they are a last resort rather than the preferred configuration mechanism.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** In progress. The exercise and implementation are still under review.

**[View my Terraform solution](./lab_10.tf)**

When completed, this implementation should:

* Compare commands executed locally and through SSH on EC2.
* Use `self` to access attributes of the instance being provisioned.
* Demonstrate the default failure behavior and `on_failure = continue`.
* Observe a destroy-time provisioner before resource deletion.

Validation commands:

```bash
terraform fmt -check
terraform validate
terraform plan
```

</details>

## Concepts to Practice

* Running `local-exec` and `remote-exec`
* Configuring an SSH `connection` block
* Using `self` inside provisioners
* Comparing creation-time and destroy-time provisioners
* Comparing `on_failure = fail` and `continue`

## Prerequisites

* Review [Provisioners](../../README.md#provisioners-the-last-resort).
* Configure AWS credentials with EC2 and security-group permissions.
* Confirm that `us-east-1` has a default VPC and subnet.
* Create an EC2 key pair and keep its private key outside the repository.
* Determine your public IPv4 address as a `/32` CIDR.

> **Security Warning:** Never commit a private key or expose SSH to `0.0.0.0/0`.

> **Cost Warning:** This lab creates an EC2 instance. Complete the cleanup procedure.

## Step-by-Step Requirements

Build the configuration in `lab_10.tf` in the order shown below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Build and Preview the EC2 Infrastructure</strong></summary>

<details>
<summary>Legacy bootstrap scenario</summary>

This exercise deliberately adds commands after Terraform creates the infrastructure so you can observe provisioner behavior. For a production EC2 bootstrap, prefer an image-building process, `user_data`, cloud-init, or a configuration-management tool.

* `local-exec` runs on the machine executing Terraform.
* `remote-exec` runs commands on a remote object and needs connectivity and authentication.
* Creation-time provisioners run after creation.
* Destroy-time provisioners run before deletion.

</details>

1. Configure the AWS provider for `us-east-1`.
2. Declare required string variables:
   * `key_pair_name`
   * `private_key_path`
   * `allowed_ssh_cidr`
3. Read the default VPC and the subnets that belong to it.
   * Select one subnet deterministically by sorting the returned subnet IDs and using the first element.
4. Discover the latest available Amazon Linux 2023 AMI.
   * Restrict the owner to Amazon.
   * Filter for the Amazon Linux 2023 name pattern and the `available` state.
5. Create one security group in the default VPC.
6. Create standalone `aws_vpc_security_group_ingress_rule` resources for:
   * SSH on port 22 from `var.allowed_ssh_cidr`.
   * HTTP on port 80 from `0.0.0.0/0`.
7. Create an `aws_vpc_security_group_egress_rule` allowing outbound IPv4 traffic.
8. Create one `t3.micro` EC2 instance in a default subnet with a public IPv4 address.
   * Use the discovered AMI and selected subnet.
   * Attach the security group and the configured EC2 key pair.

Do not mix standalone security-group rule resources with inline `ingress` or `egress` blocks on the same security group.

Create a non-committed `personal.auto.tfvars`:

```hcl
key_pair_name    = "your-key-pair-name"
private_key_path = "/absolute/path/outside-the-repository/key.pem"
allowed_ssh_cidr = "YOUR.PUBLIC.IP.ADDRESS/32"
```

Confirm it is ignored, then run:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

Confirm:

* Terraform proposes exactly five resources: one EC2 instance, one security group, two ingress rules, and one egress rule.
* SSH accepts only your `/32` CIDR.
* The private-key path and key contents are not part of the repository.
* The selected AMI and subnet belong to `us-east-1`.

Do not apply yet. Add the provisioners in Part 2 before creating the instance.

</details>

<details>
<summary><strong>Part 2: Add Provisioners, Deploy, and Verify</strong></summary>

9. Add a `remote-exec` provisioner to the EC2 instance.
   * Place its `connection` block inside that provisioner.
   * Set the connection type to SSH and the user to `ec2-user`.
   * Read the private key with `file(var.private_key_path)` and use `self.public_ip` as the host.
   * Install Nginx with `dnf` and enable and start it with `systemctl`.
10. Add a creation-time `local-exec` provisioner.
    * Write the created instance's public IP to `server_info.txt` on the Terraform operator's machine.
    * Use `self.public_ip`; make the creation record replace any older contents in that file.
11. Add a destroy-time `local-exec` provisioner.
    * Set `when = destroy`.
    * Append a message containing `self.id` to `server_info.txt` so the creation record remains visible.
12. Output the HTTP URL as `application_url`.

Run:

```bash
terraform fmt
terraform validate
terraform plan
```

Provisioners do not appear as separate resources in the plan. Confirm that the plan still proposes the same five AWS resources, then review and run:

```bash
terraform apply
terraform output -raw application_url
```

Inspect `server_info.txt` and open the URL. Confirm:

* The local file contains the instance's public IP.
* Nginx responds through the output URL.
* The local file and remote Nginx installation were produced in different execution environments.

</details>

<details>
<summary><strong>Part 3: Compare Default Failure with on_failure = continue</strong></summary>

Perform both stages below so you observe the difference rather than only reading about it.

**Stage A: Default failure behavior**

1. Add an invalid command to the end of the `remote-exec` inline list:

```hcl
"command-that-does-not-exist"
```

2. Do not set `on_failure`; its default value is `fail`.
3. Force the creation-time provisioner to run on a replacement instance:

```bash
terraform plan -replace=aws_instance.web_server
terraform apply -replace=aws_instance.web_server
```

The apply should fail when the invalid command runs. Run a normal `terraform plan` and confirm that Terraform proposes replacing the instance because the failed creation-time provisioner left it tainted.

**Stage B: Continue after failure**

4. Keep the invalid command and set this inside `remote-exec`:

```hcl
on_failure = continue
```

5. Request replacement again so the creation-time provisioner reruns:

```bash
terraform plan -replace=aws_instance.web_server
terraform apply -replace=aws_instance.web_server
```

Terraform should report the failed command as a warning, finish the apply, and leave the new instance untainted. Run a normal plan and expect no changes.

Remove the invalid command and the `on_failure` override. Run another normal plan and expect no changes because changing only a creation-time provisioner does not automatically rerun it on an existing instance.

</details>

<details>
<summary><strong>Part 4: Observe the Destroy-Time Provisioner</strong></summary>

Keep the complete EC2 resource block and restore the valid provisioner configuration before cleanup. Inspect the creation record in `server_info.txt`, then run:

```bash
terraform destroy
```

Watch `server_info.txt` during the operation. The destroy-time provisioner should append its message before Terraform reports that the EC2 instance was destroyed.

A destroy-time provisioner does not run if its entire resource block is removed from configuration before destruction.

Confirm that the file contains both the original creation record and the appended destruction record.

</details>

## Design Reflection

Before opening the explanation, answer these questions:

1. Where does `local-exec` run, and where does `remote-exec` run?
2. Why does `remote-exec` need a connection block while `local-exec` does not?
3. Why are provisioners considered a last resort?
4. What risk does `on_failure = continue` introduce?
5. Why must you request replacement to repeat a creation-time provisioner?
6. What happens to a destroy-time provisioner if the complete resource block is removed first?

<details>
<summary>Review the design questions and answers</summary>

1. `local-exec` runs where Terraform runs; `remote-exec` runs commands on the remote target.
2. Terraform needs remote connectivity and authentication details to reach the instance through SSH.
3. Terraform cannot model, diff, or reverse their side effects as reliably as provider-managed resources or image/user-data workflows.
4. Terraform can report a successful apply even though required machine configuration is incomplete.
5. Creation-time provisioners run as part of resource creation, not on every plan or apply.
6. Terraform no longer has the destroy-time provisioner configuration, so it cannot execute it.

The goal is to understand provisioner behavior and risk, not to treat provisioners as the normal way to configure servers.

</details>

## Cleanup

Part 4 performs the infrastructure cleanup. Confirm the instance, security group, and standalone rules are deleted. Remove `server_info.txt` and `personal.auto.tfvars`. Keep the private key outside the repository.

Run `terraform state list` and confirm that the lab has no remaining managed instances.

## Exam Takeaways

<details>
<summary>Review the exam takeaways</summary>

* `remote-exec` requires connection information.
* `self.public_ip` refers to the current resource instance.
* Failed creation-time provisioners taint the resource by default.
* `on_failure = continue` warns and continues.
* Destroy-time provisioners run before destruction, not afterward.
* Prefer declarative and provider-native alternatives to provisioners.

</details>
