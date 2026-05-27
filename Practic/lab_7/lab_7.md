# 🛠️ Lab 8: Nested Resource Loops (Dynamic Blocks)

## Concepts to Practice
* Nested block configuration
* `dynamic` blocks
* Using `for_each` inside a resource
* The `content` and `iterator` properties

---

## Objective
Experience the rigidity of hardcoded nested blocks by deploying a static AWS Security Group. Then, refactor the code to use a `dynamic` block, allowing the firewall rules to be generated dynamically from a complex map variable.

---

## The Requirements

### Phase 1: The Hardcoded Anti-Pattern
Create an AWS Security Group using standard, hardcoded `ingress` (inbound) blocks. This represents legacy code where every single port opening requires a manual copy-paste of the entire nested block.

### Phase 2: The Dynamic Refactor
Delete the hardcoded blocks and replace them with a `dynamic` block.
1. **The Variable:** Create a map of objects containing the target ports and CIDR ranges.
2. **The `dynamic` Engine:** Use `dynamic "ingress"` with a `for_each` loop pointing to your variable.
3. **The `content` Template:** Map the `from_port`, `to_port`, and `cidr_blocks` arguments to the current loop iteration using `ingress.value`.

---

## Terraform Code (`lab_8.tf`)

### Phase 1 Code: The Static Approach
Copy this into your `main.tf` and run `terraform plan` to see what it generates.

```hcl
provider "aws" {
  region = "us-east-1"
}

# ❌ The Rigid Way: Repetitive, hardcoded blocks
resource "aws_security_group" "static_sg" {
  name        = "static-web-sg"
  description = "Security group with hardcoded rules"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
}
```

### Phase 2 Code: The Dynamic Refactor
Delete the `aws_security_group` block from Phase 1 and replace it with this dynamic architecture.

```hcl
# 1. The Variable: Data decoupled from logic
variable "web_ingress_rules" {
  type = map(object({
    port = number
    cidr = string
  }))
  default = {
    "http"  = { port = 80,  cidr = "0.0.0.0/0" }
    "https" = { port = 443, cidr = "0.0.0.0/0" }
    "ssh"   = { port = 22,  cidr = "10.0.0.0/8" }
  }
}

# 2. The Dynamic Resource
resource "aws_security_group" "dynamic_sg" {
  name        = "dynamic-web-sg"
  description = "Security group powered by dynamic blocks"

  # ✅ The Dynamic Block Way
  dynamic "ingress" {
    # Loop over the variable map
    for_each = var.web_ingress_rules
    
    # Define the template for each generated block
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      # Notice the brackets: cidr_blocks expects a list!
      cidr_blocks = [ingress.value.cidr] 
    }
  }
}
```

---

## Step-by-Step Implementation Guide

#### Step 1: Execute Phase 1
Drop the Phase 1 code into your configuration and run:
```bash
terraform init
terraform plan
```
Take note of how the terminal plans to create the Security Group with three distinct ingress rules.

#### Step 2: Implement the Refactor
Replace the rigid resource with the Phase 2 variable and dynamic block. Run `terraform plan` again.
Notice that the output plan looks **exactly the same**. The end result in AWS does not change, but your code is now infinitely scalable. 

#### Step 3: Test the Flexibility
To prove why this is powerful, add a new rule to your `default` variable block (for example, adding port `8080` for a proxy). 
```hcl
    "proxy" = { port = 8080, cidr = "0.0.0.0/0" }
```
Run `terraform plan`. You successfully added a new firewall rule strictly by updating the data variable, without ever touching the core resource logic!