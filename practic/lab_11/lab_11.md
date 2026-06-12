🛠️ Lab 11: The Modular Migration
=================================

Concepts to Practice
--------------------

*   Standard Module Structure (HashiCorp Best Practices)
    
*   Root vs. Child Module Architecture
    
*   Input Variables for Parameterization
    
*   Output definition and extraction
    
*   Local path module sourcing
    

Objective
---------

Refactor checkpoint_1 (Compute + Storage) into a professional, reusable modular architecture. You will split your configuration into two distinct domains (web_cluster and storage_vault) and orchestrate them from a single Root Module.

Directory Setup
---------------
```hcl
lab_11/
├── main.tf          (Root: Orchestrator)
├── variables.tf     (Root: Definitions)
├── outputs.tf       (Root: Aggregated outputs)
├── terraform.tfvars
├── README.md
└── modules/
    ├── web_cluster/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │   └── README.md
    └── storage_vault/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
        └── README.md

```

Architectural Requirements & Implementation Rules
-------------------------------------------------

### 1\. Domain Separation

-   **Module A (`web_cluster`):** Handles the Security Group and EC2 nodes.

-   **Module B (`storage_vault`):** Handles the S3 bucket configuration.

-   **Root Module:** Acts as the orchestrator; holds the Provider config and manages variable passing.

### 2\. Root Module Definition (`/lab_11/main.tf`)

-   **Provider Management:** Retain the `terraform {}` block and `provider "aws" {}`.

-   **Data Source Integration:** Move the `aws_ami` data source to the root (so it can be shared or updated globally).

-   **Orchestration:** Call both the `web_cluster` module and the `storage_vault` module.

-   **Variable Injection:** Pass the `ami_id` (retrieved from the data source) and `target_zones` (from a `.tfvars` file) into the modules.

-   **Output Aggregation:** Capture the outputs from both modules and present the final cluster inventory.

### 3\. Module A Requirements (`modules/web_cluster/`)

-   **Inputs (Variables):** `ami_id` (string), `instance_type` (string), `target_zones` (list of strings/set).

-   **Logic:** Define the `aws_security_group` inside this module. Define the `aws_instance` resource using the `for_each` meta-argument. Use the passed variables (no hardcoding).

-   **Outputs:** Return the map of availability zones to public IPs.

### 4\. Module B Requirements (`modules/storage_vault/`)

-   **Inputs (Variables):** `bucket_prefix` (string) to define the unique identifier for the S3 bucket.

-   **Logic:** Defines an `aws_s3_bucket` resource. Uses the passed `bucket_prefix` variable to ensure resource naming adheres to project standards.

-   **Outputs:** Returns the following values for use in the root module:

-   `bucket_id`: The name of the provisioned S3 bucket.

-   `bucket_arn`: The ARN of the bucket.

-   `bucket_domain_name`: The domain name associated with the bucket.

### 5\. Implementation Rules (Field Standards)

-   **Strict Isolation:** No `provider` blocks allowed inside child modules.

-   **Parameterization:** Strictly forbidden from using hardcoded values (e.g., "t3.micro") inside child modules.

-   **Dependency Handling:** Associate the Security Group via `vpc_security_group_ids` within the `web_cluster` module.
    - **Production Note**: In a real-world production environment, it is best practice to decouple network security from compute. This involves creating Security Groups in a separate network module and passing the IDs into the compute module as a variable (vpc_security_group_ids).
Execution & Testing Steps

-   **State Safety:** Use `moved` blocks in your root configuration if renaming resources to prevent unintended destruction.



-------------------------

#### Phase 1: Initialization

1.  Ensure your directory structure matches the tree above exactly.
    
2.  Navigate to lab\_11/ in your terminal.
    
3.  Run terraform init. You will see Terraform initialize the local module path.
    

#### Phase 2: Planning & Deployment

1.  Run terraform plan.
    
2.  Observe how Terraform now identifies the resources inside the module (module.web\_cluster.aws\_instance.web).
    
3.  Run terraform apply -auto-approve.
    

#### Phase 3: Verification

1.  Check the output in your terminal; it should display the final\_ip exported from the module.
    
2.  Verify that the file structure remains clean and that the main.tf in the root is now significantly smaller than your previous non-modular code.
    

> **Pro-Tip:** If terraform init fails, ensure your source path accurately points to the directory containing the main.tf file of your child module (./modules/web\_cluster).