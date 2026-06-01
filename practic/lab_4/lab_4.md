# 🛠️ Lab 4: The Index-Based Network (The `count` Approach)

## Concepts to Practice
* `count`
* `length()`
* `element()` or list indexing
* `keys()` / `values()`

---

## Objective
Deploy multiple AWS VPCs using a single resource block driven by `count`. Because `count` cannot read maps directly, you will need to use collection functions to break your data down into ordered lists.

---

## The Requirements

### 1. The Infrastructure Configuration Map
Keep the same map variable structure so we can compare apples to apples later. Notice that the keys are clean strings this time so we can focus purely on indexing:

```hcl
variable "environments" {
  type = map(object({
    cidr = string
  }))
  default = {
    staging    = { cidr = "10.1.0.0/16" }
    production = { cidr = "10.2.0.0/16" }
  }
}
```

### 2. The `count` Structural Challenge
A `count` loop only understands integers (e.g., `count = 2`).
Set your `count` argument dynamically by calculating the number of items inside your map variable using the `length()` function.

### 3. Extracting Map Data via List Indexes
Because `count` relies on numbers (`count.index = 0`, `count.index = 1`), you cannot query your map using string keys. You must extract the keys and values into distinct lists first:

* **The Names (Keys):** Use the `keys(var.environments)` function to turn your map keys into a list: `["staging", "production"]`. Then, grab the current item using index brackets `[count.index]`.
* **The CIDRs (Values):** Use the `values(var.environments)` function to extract the object configurations into a list. From there, navigate to the specific index and grab the cidr: `values(var.environments)[count.index].cidr`.

### 4. The Resource Block (`aws_vpc`)
Feed the indexed CIDR string directly into the `cidr_block` argument.
Tag the VPC `Name` dynamically to match the current environment key name (e.g., `vpc-staging`, `vpc-production`).