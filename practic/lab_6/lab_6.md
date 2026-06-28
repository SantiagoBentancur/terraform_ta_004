# 🛠️ Lab 6: The Blast Radius (`count` vs. `for_each`)

## Concepts to Practice

* Side-by-side loop comparison
* The `toset()` type conversion function
* Resource instance addressing (`[0]` vs. `["key"]`)
* Day 2 operations (safely modifying active infrastructure)

---

## Objective

Deploy two comparable sets of infrastructure using `count` and `for_each`, both driven by a single list variable. Once deployed, simulate a real-world change by deleting an item from the middle of the list. This demonstrates how `count` indexes can shift while `for_each` preserves stable keys.

---

## The Requirements

### 1. The Shared List Variable

Create a simple list of strings representing three project modules. Both looping methods will read from this exact same list.

```hcl
variable "project_modules" {
  type    = list(string)
  default = ["analytics", "billing", "security"]
}
```

### 2. The `count` Resource Block

Create AWS SNS topics using the `count` method. Use `length()` to set the loop, and index brackets `[count.index]` to assign the name.

### 3. The `for_each` Resource Block

Create a second set of AWS SNS topics using `for_each`.

* **The Catch:** `for_each` cannot directly loop over a `list(string)`. It requires a map or a set.
* Use the **`toset()`** function directly inside the loop argument to safely convert the list into a set of unique string keys: `for_each = toset(var.project_modules)`.
* Use `each.key` to assign the name.

---

## Terraform Code (`lab_6.tf`)

```hcl
provider "aws" {
  region = "us-east-1"
}

# 1. The Shared Variable List
variable "project_modules" {
  type    = list(string)
  default = ["analytics", "billing", "security"]
}

# 2. The Count Approach (Vulnerable to index shifting)
resource "aws_sns_topic" "count_topics" {
  count = length(var.project_modules)
  name  = "count-topic-${var.project_modules[count.index]}"
}

# 3. The for_each Approach (Stable keys prevent index shifting)
resource "aws_sns_topic" "foreach_topics" {
  # Convert the list to a set so for_each can use its values as stable keys
  for_each = toset(var.project_modules)
  name     = "foreach-topic-${each.key}"
}
```

---

## Step-by-Step Implementation & The "Blast Radius" Test

This lab requires a two-phase execution. First, we build the infrastructure. Then, we modify the code to see how Terraform reacts.

#### Phase 1: The Initial Deployment

1. Run `terraform init` and `terraform apply -auto-approve`.
2. Terraform will create six SNS topics: three with `count` and three with `for_each`.

#### Phase 2: The Day 2 Modification (The Trap)

Imagine the company shuts down the billing department. You need to remove "billing" from your infrastructure.

1. Open your `lab_6.tf` file.
2. Delete `"billing"` from the middle of your variable list:
   ```hcl
   # Change this:
   default = ["analytics", "billing", "security"]
   
   # To this:
   default = ["analytics", "security"]
   ```
3. Save the file.

#### Phase 3: Witness the Blast Radius

Do not apply! Just run the evaluation engine to see what Terraform *wants* to do:

```bash
terraform plan
```

### 🔍 Analyzing the Terminal Output

Scroll through your plan output carefully. You will see two completely different behaviors:

**The `for_each` Success:**

* Terraform sees that `aws_sns_topic.foreach_topics["billing"]` is gone.
* It plans to **destroy** exactly one resource: the billing topic.
* The "analytics" and "security" topics are untouched.

**The `count` Index Shift:**

* Terraform sees that index `[1]` shifted from "billing" to "security", and index `[2]` no longer exists.
* It plans to **destroy** `aws_sns_topic.count_topics[2]`, the original security topic.
* It plans to **replace** `aws_sns_topic.count_topics[1]`, changing its name from "billing" to "security".
* Removing one list item therefore affects two resource instances because their numeric addresses shifted.
