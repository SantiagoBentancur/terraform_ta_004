# 🛠️ Lab 3: The Chameleon Deployment (Advanced Logic)

## Objective
Build a dynamic Terraform configuration that changes its behavior, instance size, and resource count on the fly based on a single environment switch (`is_production`).

## Requirements

### 1. Variables
* **`is_production`**: Create a boolean variable named `is_production` that defaults to `false`.
* **`instance_types`**: Create a map variable named `instance_types` with two keys: `"true"` and `"false"`. If `"true"`, the value must be `"t3.small"`. If `"false"`, the value must be `"t3.micro"`.

### 2. Data Source
* Use the `aws_ami` data source to dynamically fetch the latest official **Amazon Linux 2023** image (using the naming pattern: `al2023-ami-*-kernel-6.1-x86_64`).

### 3. EC2 Resource (`aws_instance`)
* **Dynamic Count**: Use a ternary conditional expression. If `is_production` is `true`, deploy **2 instances**. If it is `false`, deploy only **1 instance**.
* **Dynamic Instance Type**: Look up the instance size from your `instance_types` map. *Hint: You must cast the boolean variable to a string using `tostring()` to match the map keys.*
* **Indexed Naming**: In the `tags` block, the `Name` tag must automatically evaluate to `"server-prod-0"`, `"server-prod-1"`, or `"server-dev-0"` depending on the environment state and the current loop iteration.

---

## Key Architectural Features
1. **Dynamic Scaling (`count` Conditional):** Avoids duplicating resource blocks by dynamically setting the instance count based on whether the target environment is production or development.
2. **Boolean-to-String Map Lookup (`tostring` casting):** Bypasses the structural limitation where Terraform maps require string keys, enabling a raw boolean configuration switch to pull string values from a lookup table.
3. **Inline Ternary Interpolation:** Evaluates structural configurations directly inside metadata strings for customized resource tracking in the AWS console.

---

## Terraform Code (`lab_3.tf`)

```hcl
provider "aws" {
  region = "us-east-1"
}

# 1. Flag switch to dictate infrastructure sizing
variable "is_production" {
  type        = bool
  description = "Toggles a specific feature on or off"
  default     = false
}

# 2. Variable mapping for instance scaling sizes
variable "instance_types" {
  type = map(string)
  default = {
    "true"  = "t3.small"
    "false" = "t3.micro"
  }
}

# 3. Dynamic Data Source targeting Amazon Linux 2023
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
}

# 4. Master Dynamic Resource Provisioning
resource "aws_instance" "ec2_lab1" {
  ami   = data.aws_ami.amazon_linux_2.id
  
  # Condition: Creates 2 instances if true, 1 instance if false
  count = var.is_production ? 2 : 1
  
  # Map lookup casting the boolean variable to a string representation
  instance_type = var.instance_types[tostring(var.is_production)]
  
  # Fully dynamic naming syntax tracking environment and sequential loop location
  tags = {
    Name = "server-${var.is_production ? "prod" : "dev"}-${count.index}"
  }
}