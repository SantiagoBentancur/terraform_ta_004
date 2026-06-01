# 🛠️ Lab 2: Multi-S3 Bucket Deployment (Unique Naming Syntax)

## Objective
Build a dynamic Terraform configuration that deploys multiple storage buckets simultaneously using a single resource block, while programmatically guaranteeing global naming uniqueness to prevent cloud provider collisions.

## Requirements

### 1. Variables
* **`s3_lab2`**: Define a standard string input variable to serve as the baseline prefix for your bucket names (e.g., `"my-project-bucket"`).

### 2. Data Source
* Use the `aws_caller_identity` data source block to automatically query and fetch your active AWS Account ID dynamically during the runtime plan phase.

### 3. S3 Resource (`aws_s3_bucket`)
* **Resource Count**: Implement a single resource block with `count = 3` to provision three distinct buckets concurrently.
* **String Formatting**: Build the unique bucket name argument by binding the variables together using the native `format()` utility. The naming taxonomy must resolve as: `[base_name]-[aws_account_id]-[index_number]`.
* **Metadata Tags**: Leverage the sequential loop variable (`count.index`) inside the resource tags to give each bucket a clear, identifiable tracking string in the AWS management console.

---

## Key Architectural Features
1. **Resource Duplication Avoidance:** Demonstrates how `count` simplifies resource scaling from a single target specification block.
2. **Dynamic Collision Protection:** Uses an organization's specific AWS Account ID to ensure that names remain separate and globally unique when running identical configurations across different provider sandboxes.
3. **Strict Type Matching:** Leverages formatting operators (`%s` and `%d`) to cleanly merge distinct datatypes (strings and index integers) into uniform structural outputs without crashing the evaluator engine.

---

## Terraform Code (`lab_2.tf`)

```hcl
provider "aws" {
  region = "us-east-1"
}

# 1. Fetch current AWS Account ID dynamically
data "aws_caller_identity" "current" {}

# 2. Base input variable for naming prefix
variable "s3_lab2" {
  type        = string
  default     = "my-project-bucket"
  description = "Base prefix string for the S3 buckets"
}

# 3. Multi-bucket resource generation block
resource "aws_s3_bucket" "lab2_buckets" {
  count = 3

  # Using the format function to construct the unique name safely
  bucket = format("%s-%s-%d", var.s3_lab2, data.aws_caller_identity.current.account_id, count.index)

  tags = {
    Identifier = "Bucket number ${count.index}"
    ManagedBy  = "Terraform"
  }
}