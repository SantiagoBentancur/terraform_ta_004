# Lab 11: Modular Infrastructure Deployment

This project orchestrates a multi-tier AWS infrastructure using reusable Terraform modules. It deploys a web cluster across multiple Availability Zones and provisions a dedicated Amazon S3 bucket for secure backups.

## Architecture

* **Root Module** – Orchestrates the deployment, configures the AWS provider, and wires the child modules together.
* **`web_cluster` Module** – Provisions EC2 instances and configures the required HTTP and SSH security rules.
* **`storage_vault` Module** – Provisions an S3 bucket to serve as a secure backup vault.

## Deployment Steps

### 1. Initialize the project

```bash
terraform init
```

### 2. Review the execution plan

```bash
terraform plan
```

### 3. Apply the configuration

```bash
terraform apply
```

## Root Outputs

| Name                | Description                                                                      |
| ------------------- | -------------------------------------------------------------------------------- |
| `cluster_inventory` | Inventory of the web cluster as a map of Availability Zone to public IP address. |

## Prerequisites

* AWS CLI configured with appropriate credentials.
* Terraform version `>= 1.14.7`.

## Project Structure

```text
.
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── modules/
│   ├── web_cluster/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── storage_vault/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── README.md
```

## Notes

* The `web_cluster` module deploys EC2 instances across the specified Availability Zones.
* The `storage_vault` module provides a dedicated S3 bucket for storing backups and project data.
