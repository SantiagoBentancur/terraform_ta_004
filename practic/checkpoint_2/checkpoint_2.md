# Checkpoint 2: Production-Inspired Three-Tier Architecture

## Project Overview

Build a modular three-tier architecture on AWS with a public entry point and isolated
application and database layers. This checkpoint evaluates module composition,
networking, security boundaries, load balancing, Auto Scaling, and environment-specific
configuration.

### Learning Objectives

By the end of this checkpoint, you should be able to:

* Design reusable Terraform modules with explicit inputs and outputs.
* Connect modules through resource attributes instead of manual dependencies.
* Separate public, private application, and isolated database networks.
* Restrict traffic by referencing security groups between tiers.
* Connect an Auto Scaling Group to an Application Load Balancer.
* Apply different capacity and availability settings to development and production.
* Validate both the Terraform configuration and the deployed application path.

### Architectural Blueprint

The infrastructure spans two Availability Zones (AZs). Production uses redundant
compute and NAT resources; development retains the same subnet layout while using
reduced capacity to control cost.

![Production-inspired three-tier architecture](assets/three-tier-architecture.png)

---

## Infrastructure Requirements

The system is divided into three distinct logical tiers.

| Tier                | Components                                             | Accessibility                                                           |
| ------------------- | ------------------------------------------------------ | ----------------------------------------------------------------------- |
| Tier 1: Public      | Application Load Balancer (ALB), NAT Gateways          | Public access allowed through the Internet Gateway                      |
| Tier 2: Private App | Auto Scaling EC2 instances hosting the web application | No direct internet access; outbound traffic routed through NAT Gateways |
| Tier 3: Isolated DB | Amazon RDS PostgreSQL                                  | Completely isolated; accepts traffic only from the Application Tier     |

---

## Required Directory Structure

Use the following target structure to keep infrastructure domains separate and make the
development and production configurations easy to compare:

```text
.
├── modules/
│   ├── network/          # VPC, Subnets, IGW, NAT Gateways
│   ├── security/         # security_groups.tf, iam.tf
│   ├── alb_tier/         # Load Balancer, Target Groups, Listeners
│   ├── compute_tier/     # ASG, Launch Templates
│   └── database/         # RDS (PostgreSQL)
├── environments/
│   ├── dev/
│   │   ├── main.tf       # Root orchestration
│   │   └── terraform.tfvars
│   └── prod/             # Full production configuration
├── scripts/
│   └── install_app.sh    # Bootstrap: Nginx setup + /health endpoint
├── .gitignore
└── README.md             # Project-wide architecture overview
```

Some directories are intentionally absent from the starter repository. Create them as
you reach the corresponding part of the checkpoint.

---

## Part 1: Networking Foundation

The architecture uses a VPC CIDR block of `10.0.0.0/16`.

Subnets are distributed across two Availability Zones to provide fault tolerance and support Multi-AZ deployments.

| Tier   | Subnet Purpose          | Availability Zones | CIDR Blocks                    |
| ------ | ----------------------- | ------------------ | ------------------------------ |
| Public | ALB and NAT Gateways    | AZ1 / AZ2          | `10.0.1.0/24`, `10.0.2.0/24`   |
| App    | Web Application Servers | AZ1 / AZ2          | `10.0.10.0/24`, `10.0.20.0/24` |
| DB     | RDS Instances           | AZ1 / AZ2          | `10.0.30.0/24`, `10.0.40.0/24` |

### Route Table Design

The following diagram shows how public, private application, and isolated database subnets are associated with route tables across both Availability Zones.

![Route table design for the three-tier architecture](assets/image.png)

### Networking Design Questions

Before implementing the network module, consider the following questions:

* Why does the VPC need an Internet Gateway?
* How is an Internet Gateway attached to the VPC?
* Why do public subnets need a route table with `0.0.0.0/0` pointing to the Internet Gateway?
* What is a NAT Gateway?
* Why should NAT Gateways be placed in public subnets?
* Why do private application subnets route outbound internet traffic through a NAT Gateway instead of directly through an Internet Gateway?
* Why should isolated database subnets not have a route to the Internet Gateway or NAT Gateway?
* How many route tables are needed for this architecture?
* How do route table associations connect public, application, and database subnets to the correct route tables?
* What outputs should the network module expose for other modules such as security, ALB, compute, and database?

---

## Part 2: Security and Session Manager

### Security Chaining

Security rules between application tiers must not rely on hard-coded IP addresses.
Instead, each private tier must reference the security group of the preceding tier. The
public ALB is the intentional exception because it accepts client traffic from the
internet.

| Security Group | Allowed Source | Allowed Ports            |
| -------------- | -------------- | ------------------------ |
| `sg_alb`       | `0.0.0.0/0`    | `80`, `443`              |
| `sg_app`       | `sg_alb`       | Application traffic only |
| `sg_db`        | `sg_app`       | PostgreSQL (`5432`)      |

Port `443` is included in `sg_alb` for a future HTTPS listener. This checkpoint does
not create that listener because HTTPS requires an ACM certificate and domain
validation. Only port `80` is used by the deployed application.

Allowing an unused port does not follow strict least privilege. It is a deliberate lab
exception so learners can discuss the future HTTPS path. In a production configuration,
add port `443` only when the HTTPS listener and certificate are ready.

The security module must output the IDs of `sg_alb`, `sg_app`, and `sg_db` for use by
the ALB, compute, and database modules.

### Access with Session Manager

The application instances live in private subnets and have no public IP addresses. Do
not open SSH port `22` or create a bastion host. Use AWS Systems Manager Session Manager
to obtain a shell through the AWS Console or CLI.

Session Manager works through outbound communication initiated by the SSM Agent on the
instance:

```text
Learner → AWS Session Manager service ← outbound HTTPS ← SSM Agent on private EC2
```

Because the instance initiates the connection, no inbound administration port is
required. In this lab, the private subnet reaches the Systems Manager endpoints through
the NAT Gateway. A future production design could replace that path with VPC endpoints.

Four pieces must work together:

1. **IAM role** — provides AWS permissions to the EC2 instance. Its trust policy must
   allow the EC2 service to assume the role.
2. **`AmazonSSMManagedInstanceCore` policy** — an AWS-managed policy attached to the
   role. It allows the SSM Agent to register the instance, exchange messages, and open
   Session Manager control and data channels.
3. **Instance profile** — the container that makes the IAM role attachable to an EC2
   instance. The launch template attaches this instance profile to every instance
   created by the Auto Scaling Group.
4. **SSM Agent and network path** — the agent must be installed and running, and the
   instance must be able to make outbound HTTPS connections to Systems Manager.

The resource relationship is:

```text
AmazonSSMManagedInstanceCore
            ↓ attached to
         IAM role
            ↓ included in
      instance profile
            ↓ attached by
      launch template
            ↓ used by
        EC2 instances
```

`AmazonSSMManagedInstanceCore` grants permissions to the **instance**. It does not grant
the learner permission to start a session. The AWS identity running the lab must also
already have permission to use Session Manager; configuring learner identities is
outside this checkpoint.

Remote access must therefore follow these requirements:

* Bastion hosts are prohibited.
* SSH ingress rules are prohibited.
* AWS Systems Manager Session Manager must be used.
* The SSM Agent must be installed and running on the selected AMI.
* The application security group must allow the required outbound HTTPS traffic.
* EC2 instances must attach an IAM role containing the following AWS-managed policy:

```text
AmazonSSMManagedInstanceCore
```

Create the IAM role and instance profile in the security module. Output the instance
profile name or ARN and pass it into the compute module for use by the launch template.

## Part 3: Bootstrap Script

Create a small `scripts/install_app.sh` script. Its purpose is only to prove that an
instance can initialize itself and pass the ALB health check.

The script should:

* Install Nginx.
* Create a static `/health` endpoint.
* Start and enable Nginx.
* Exit when a command fails.

A minimal implementation is sufficient:

```bash
#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
printf 'healthy\n' > /var/www/html/health
systemctl enable --now nginx
```

Keep the compute module reusable by accepting the encoded user data as an input. The
environment root module should read and encode the script, for example:

```hcl
user_data = filebase64("${path.module}/../../scripts/install_app.sh")
```

Pass that value to the launch template's `user_data` argument. The exact relative path
depends on where the environment root module is located.

## Part 4: Application Load Balancer

Create an internet-facing Application Load Balancer that provides the only public entry
point to the application.

Requirements:

* Deploy the ALB into both public subnets.
* Attach `sg_alb` to the ALB.
* Create an HTTP listener on port `80`.
* Create an HTTP target group on port `80`.
* Configure the target group health check to request `/health` and expect HTTP `200`.
* Output the ALB DNS name and target group ARN.

The target group ARN is consumed by the compute module so that the Auto Scaling Group
can register and deregister application instances automatically.

## Part 5: Compute Layer

The compute tier must adhere to the following requirements:

* Use `aws_launch_template`.
* Use `aws_autoscaling_group`.
* Do not use legacy Launch Configurations.
* Deploy application instances into both private application subnets (`app_1` and `app_2`).
* Attach `sg_app` to the instances through the launch template.
* Attach the Auto Scaling Group to the ALB application target group.
* Use one Auto Scaling Group spanning both Availability Zones. Capacity values represent
  the total number of instances across both Availability Zones, not a per-AZ count.

Before implementing the module, answer these design questions:

1. Why does an Auto Scaling Group use a launch template instead of managing individual
   `aws_instance` resources?
2. How do desired capacity, health checks, and scaling policies affect ASG behavior?

### Provided Ubuntu AMI Data Source

The compute tier combines several related concepts: launch templates, Auto Scaling,
private subnet placement, target group registration, health checks, and instance
bootstrapping. To keep the exercise focused on those concepts, the Ubuntu AMI lookup is
provided as starter code.

Add the following block to `modules/compute_tier/main.tf`:

```hcl
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-${var.ubuntu_codename}-${var.ubuntu_version}-amd64-server-*"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

This data source searches AMIs published by Canonical, filters them by the configured
Ubuntu codename and version, limits the result to HVM images, and selects the most
recent matching image. Declare `ubuntu_codename` and `ubuntu_version` as module inputs
so that the lookup remains configurable.

Use the selected AMI in the launch template through:

```hcl
image_id = data.aws_ami.latest_ubuntu.id
```

The learner is still responsible for implementing the launch template, Auto Scaling
Group, module inputs, subnet and target group connections, IAM instance profile, and
user data.

To keep the lab cost-conscious, use the following environment-specific compute
capacity:

| Environment | Instance Type | Minimum | Desired | Maximum |
| ----------- | ------------- | ------: | ------: | ------: |
| Dev         | `t3.micro`    | 1       | 1       | 2       |
| Prod        | `t3.small`    | 2       | 2       | 3       |

Development normally runs one instance and therefore does not provide compute-level
high availability. Production normally runs two instances, allowing the Auto Scaling
Group to distribute them across the two Availability Zones. AWS Auto Scaling performs
Availability Zone balancing, but the capacity settings do not guarantee an exact number
of instances in each Availability Zone at every moment.

These settings are intended to minimize lab costs and do not guarantee that the complete
architecture is free. In particular, NAT Gateways, the Application Load Balancer, data
transfer, storage, and simultaneous dev and prod deployments may incur charges.

### Auto Scaling Scope

In this checkpoint, the Auto Scaling Group maintains desired capacity, replaces
unhealthy instances, and balances capacity across the configured Availability Zones.
It does not change desired capacity in response to CPU utilization or request volume.
CloudWatch alarms and dynamic scaling policies are reserved for a future lab.

## Part 6: Database Layer

Create an Amazon RDS for PostgreSQL database in the isolated database tier.

Requirements:

* Create a DB subnet group containing both isolated database subnets.
* Attach `sg_db` to the database.
* Set `publicly_accessible = false`.
* Use PostgreSQL and port `5432`.
* Use the environment-specific instance class and Multi-AZ settings shown below.
* Pass the database password through a variable rather than writing it directly in the
  RDS resource.
* Do not commit the password or output it from the module.

> **Credential Warning:** Secure secret management and Terraform sensitive values are
> outside the scope of this checkpoint and will be covered in a future lab. Use only a
> temporary lab password, never reuse a real password, and remember that Terraform may
> store the value in its state file.

## Environment-Specific Configuration

Development and Production environments must maintain consistent architecture while differing in scale and resiliency requirements.

| Environment | NAT Gateways   | Database Instance Type | Multi-AZ |
| ----------- | -------------- | ---------------------- | -------- |
| Dev         | 1              | `db.t3.micro`          | No       |
| Prod        | 2 (one per AZ) | `db.t3.small`          | Yes      |

For the development environment, the network still creates both Availability Zones and all corresponding subnets so the layout remains consistent with production. However, to keep the lab simpler and reduce cost, dev provisions only one NAT Gateway. In that case, both private application subnets route outbound internet traffic through the NAT Gateway in the first public subnet.

---

## Part 7: Root Module Integration

Terraform automatically builds the dependency graph through resource references.
Do not add `depends_on` between modules when an input already references another
module's output.

The root module must connect the modules through the following logical relationships:

```text
network
   ├──→ security
   │       ├──→ alb_tier
   │       │       └──→ compute_tier
   │       └──→ database
   ├──→ alb_tier
   ├──→ compute_tier
   └──→ database
```

Examples of required data flow include:

* Network VPC ID → security and ALB modules.
* Public subnet IDs → ALB module.
* Private application subnet IDs → compute module.
* Isolated database subnet IDs → database module.
* ALB security group ID → ALB module.
* Application security group ID → compute module.
* Database security group ID → database module.
* ALB target group ARN → compute module.
* IAM instance profile → compute module.
* Encoded bootstrap script → compute module.

---

## Part 8: Validation

Run the following checks before considering the checkpoint complete:

```bash
terraform fmt -check -recursive
terraform validate
terraform plan
```

After deployment, verify that:

* The ALB DNS name responds over HTTP.
* `http://<alb-dns-name>/health` returns HTTP `200`.
* EC2 instances have no public IPv4 addresses.
* Application instances are healthy in the target group.
* The Auto Scaling Group uses both private application subnets.
* Session Manager can connect to an instance without SSH.
* The database is not publicly accessible.
* Application security rules allow only the intended tier-to-tier traffic.

---

## Definition of Done

The implementation is considered complete when all of the following criteria are satisfied.

### Modularization

* Environment-specific and reusable values are exposed through `variables.tf`.
* Fixed architectural constants are clearly documented when kept inside a module.
* Modules remain self-contained and reusable.
* Module dependencies are created through inputs and outputs.

### Documentation

* Every module contains a `README.md`.
* Each module README includes:

  * Inputs table.
  * Outputs table.
  * Module usage examples where applicable.

### Tagging

All taggable AWS resources must include the following tags:

| Tag           | Value                        |
| ------------- | ---------------------------- |
| `Name`        | Resource-specific identifier |
| `Environment` | Deployment environment       |
| `Project`     | Project name                 |
| `ManagedBy`   | `Terraform`                  |

### State Management

* Local Terraform state is acceptable for this checkpoint.
* Migration to remote state using S3 and DynamoDB will be implemented in a later phase.

### Final Checks

* `terraform fmt -check -recursive` succeeds.
* `terraform validate` succeeds.
* `terraform plan` contains no unexpected resources or replacements.
* All functional validation checks in Part 8 pass.
