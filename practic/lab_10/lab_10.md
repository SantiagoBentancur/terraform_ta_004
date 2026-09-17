# Lab 10: Provisioners and Connections

## Objective

A team inherits a small legacy EC2 deployment that has no image pipeline or configuration-management process. During an incident, an operator must record the instance address on their own machine, connect to the new host over SSH, install Nginx, and leave a record when the host is removed. The team wants to understand exactly where those commands run, what Terraform knows about their side effects, and what happens when one of them fails.

Use this controlled scenario to compare local and remote execution, SSH connections, creation-time and destroy-time behavior, and `on_failure = continue`. The exercise is intentionally operational and imperfect: it demonstrates why provisioners appear in Terraform and certification material, while also showing why they are usually not the right production design.

<details>
<summary><strong>Santiago's Implementation</strong></summary>

> **Status:** Completed.

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
* Prepare an EC2 key pair for `us-east-1` and keep its private key outside the repository.
* Determine your public IPv4 address as a `/32` CIDR.

> **Security Warning:** Never commit a private key or expose SSH to `0.0.0.0/0`.

<details>
<summary>Where does the EC2 key pair come from?</summary>

Yes—the private key is normally generated or stored on the laptop (or other machine) where you run Terraform. Terraform does not generate the key pair in this lab. Use one of these AWS-supported workflows before you begin:

* Create the key pair in Amazon EC2. AWS stores the public key and lets you download the private key once to your computer.
* Generate a compatible SSH key pair on your computer, keep the private key locally, and import only the public key into Amazon EC2.

In both cases, `key_pair_name` identifies the public key registered in EC2, while `private_key_path` points to the matching private key on the machine running Terraform. They must represent the same key pair, and the EC2 key pair must exist in `us-east-1`.

</details>

> **Cost Warning:** This lab creates an EC2 instance. Complete the cleanup procedure.

## Step-by-Step Requirements

Build the configuration in `lab_10.tf` in the order shown below. Do not open or copy another solution first.

<details>
<summary><strong>Part 1: Build and Preview the EC2 Infrastructure</strong></summary>

<details>
<summary>Legacy bootstrap scenario</summary>

Provisioners are imperative hooks attached to a resource. By default, a creation-time provisioner runs immediately after Terraform creates that resource, while a destroy-time provisioner runs before Terraform deletes it. Terraform records the resource, but it cannot model every side effect of the commands as part of the resource's normal desired state.

HashiCorp recommends exhausting purpose-built alternatives before using provisioners. Depending on the problem, those alternatives include a prebuilt machine image, `user_data` or cloud-init for first-boot configuration, and a configuration-management tool such as Ansible for repeatable package and service configuration.

This lab deliberately uses provisioners so you can observe their behavior. It is not a recommendation to install Nginx this way in a production platform.

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
   * Do not assign Terraform defaults. These values depend on the operator and must be supplied through the non-committed `personal.auto.tfvars` file shown below. A variable with no default is intentionally required at plan time.
3. Create an `aws_vpc` data source that selects the default VPC.
   * Use the data source's `default` argument so Terraform queries the existing default VPC instead of creating or managing one.
4. Discover the latest available Amazon Linux 2023 AMI.
   * Restrict the owner to Amazon.
   * Filter for the Amazon Linux 2023 name pattern and the `available` state.
5. Create one security group in the default VPC.
6. Create standalone `aws_vpc_security_group_ingress_rule` resources for:
   * SSH on port 22 from `var.allowed_ssh_cidr`.
   * HTTP on port 80 from `0.0.0.0/0`.
7. Create one `aws_vpc_security_group_egress_rule` associated with the security group.
   * This rule controls traffic leaving the instance; it is separate from the inbound SSH and HTTP rules.
   * Allow outbound IPv4 traffic to `0.0.0.0/0`.
   * Set `ip_protocol = "-1"` to allow all protocols. Do not set `from_port` or `to_port` when every protocol is allowed.
8. Create one `t3.micro` EC2 instance in a subnet from the default VPC with a public IPv4 address.
   * Create an `aws_subnets` data source that filters existing subnets by the default VPC ID.
   * Select one subnet deterministically by sorting the returned subnet IDs and using the first element. This reads an existing subnet; it does not create one.
   * Use the discovered AMI and selected subnet ID.
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

Provisioners are attached inside the resource that they act on. The `local-exec` provisioner runs on the machine executing Terraform and therefore does not need a `connection` block. The `remote-exec` provisioner runs commands on the EC2 instance, so it needs connection details nested inside the provisioner:

```hcl
provisioner "remote-exec" {
  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = self.public_ip
    private_key = file(var.private_key_path)
  }

  inline = ["...commands run on the instance..."]
}
```

`self` refers to the current `aws_instance` resource. Using `self.public_ip` avoids creating a reference cycle to the resource from inside its own block. The private key is read locally by Terraform and is used to authenticate the SSH connection; it is not uploaded as a file to the instance.

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

Do not set `on_failure` yet. Its default is `fail`, which lets Part 3 demonstrate the normal failure behavior first.

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

### When a creation-time provisioner fails

If a creation-time provisioner fails with the default failure behavior, Terraform marks the resource as **tainted** because it may be only partially configured. During the next `terraform apply`, Terraform normally plans to replace the tainted resource. The taint is Terraform's way of refusing to trust a resource whose creation completed but whose required post-creation commands did not.

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

The apply should fail when the invalid command runs. Run a normal `terraform plan` and confirm that Terraform proposes replacing the instance because the failed creation-time provisioner left it tainted. Do not label this a normal resource drift correction: the replacement is a consequence of the failed provisioner.

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
