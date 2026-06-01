# 🏗️ Checkpoint Project 1: The SAA "Multi-AZ Web Tier"

## The Scenario
A client needs a highly available web architecture designed to AWS Solutions Architect Associate (SAA) standards. If an AWS data center (Availability Zone) goes offline, their application must stay online. They also have a critical backup storage bucket that must be protected from accidental deletion at all costs.

**The AWS Architecture (SAA Concepts):**
* **Multi-AZ Compute:** EC2 instances deployed into 2 completely different Availability Zones (`us-east-1a` and `us-east-1b`).
* **Security:** A single Security Group attached to all instances allowing port 80 (HTTP) and port 22 (SSH).
* **Data Protection:** An S3 bucket simulating a critical data vault.

---

## Technical Requirements Sheet

Create a clean file named `main.tf` inside your project folder and implement the following specifications exactly:

#### 1. Input Variables & Security Guards
* Create a variable named `instance_type`.
* Set its default value to `"t3.micro"`.
* **The Guardrail:** Add a `validation` block checking that the input is *only* allowed to be a `"t2.micro"` or a `"t3.micro"`. If a user tries to pass an expensive instance size, reject the plan with a clear error message.

#### 2. The Multi-AZ Compute Tier
* Create a variable named `target_zones` as a `list(string)` containing `["us-east-1a", "us-east-1b"]`.
* Write a **single** `aws_instance` resource block named `web_nodes`.
* **The Loop:** Use a `for_each` loop to process the `target_zones` list. *(Remember: `for_each` requires a set, so you must use the `toset()` function).*
* Set the `availability_zone` argument of the instance dynamically using the loop key.
* **Dynamic AMI:** Do not hardcode the AMI. Use a `data` block to dynamically fetch the most recent Ubuntu 22.04 AMI owned by Canonical (Owner ID: `099720109477`). Reference this data block inside your EC2 instance.

#### 3. Networking & Access Control
* Create an `aws_security_group` named `web_traffic_rules`.
* Configure it to allow inbound traffic on Port `80` (HTTP) and Port `22` (SSH) from any IP address (`0.0.0.0/0`).
* Attach this security group to your EC2 instances inside your loop configuration.

#### 4. The Critical Storage Vault
* Create an `aws_s3_bucket` with a `bucket_prefix` of `"saa-backup-vault-"`.
* **The SAA Requirement:** Production backups must never be accidentally deleted by a bad code run. Add a `lifecycle` block containing the exact argument that acts as a hard safety lock against destruction.

#### 5. Output Mapping
* Create an output named `production_cluster_inventory`.
* **The Loop:** Use a `for` loop to generate a clean dictionary map.
* **The Goal:** The final terminal output must print a map where the **Key** is the AWS Availability Zone, and the **Value** is the **Public IP Address** of the server running inside that specific zone.