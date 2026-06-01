# 🛠️ Lab 9: Production Guardrails & CLI Operations

## Concepts to Practice
* `lifecycle` (`prevent_destroy`, `ignore_changes`)
* Explicit Dependencies (`depends_on`)
* State Refactoring (`moved` blocks)
* Day 2 CLI Ops (`-replace`, `terraform graph`, saved plans)

---

## Objective
Deploy a mock production database (using an S3 bucket to stay in the free tier) and a web server. You will apply lifecycle hooks to protect the database from accidental deletion and tell Terraform to ignore out-of-band manual changes to the web server. Finally, you will execute a state move, troubleshoot a common refactoring error, and generate a visual dependency graph.

---

## Terraform Code (`lab_9.tf`)

```hcl
provider "aws" {
  region = "us-east-1"
}

# 1. The "Production Database" (Protected)
resource "aws_s3_bucket" "prod_db_backup" {
  bucket_prefix = "critical-db-backup-"

  lifecycle {
    # Hard safety lock to prevent accidental deletion
    prevent_destroy = true
  }
}

# 2. The App Server (Ignoring Manual Changes)
resource "aws_instance" "app_server" {
  ami           = "ami-0c7217cdde317cfec" # Standard Ubuntu AMI
  instance_type = "t3.micro"
  
  # Explicitly wait for the backup bucket to exist before booting the server
  depends_on = [aws_s3_bucket.prod_db_backup]

  tags = {
    Name = "frontend-app"
  }

  lifecycle {
    # If someone manually adds a tag in the AWS Console, Terraform will not overwrite it
    ignore_changes = [tags]
  }
}

# 3. The State Refactor (Uncomment this during Phase 3)
# moved {
#   from = aws_instance.app_server
#   to   = aws_instance.frontend_web_server
# }
```

---

## Step-by-Step CI/CD Execution

This lab is heavy on terminal commands to simulate a real-world pipeline.

#### Phase 1: Safe CI/CD Planning
In a production pipeline, you save the plan to a binary file to guarantee what is reviewed is exactly what is applied.
1. Run: `terraform plan -out=production.plan`
2. Inspect the binary plan: `terraform show production.plan`
3. Execute the locked plan: `terraform apply production.plan`

#### Phase 2: Testing the Guardrails
1. **Test `ignore_changes`:** Log into the AWS Console, find your newly created EC2 instance, and manually add a new tag (e.g., `Environment = Production`). Go back to your terminal and run `terraform plan`. Notice Terraform says `No changes` because it is actively ignoring the tags attribute!
2. **Test `prevent_destroy`:** Run `terraform destroy`. Terraform will throw a massive error refusing to delete the infrastructure because the S3 bucket is protected by the lifecycle rule.

#### Phase 3: The `moved` Block Refactor & Troubleshooting
Your lead architect wants the `app_server` resource renamed to `frontend_web_server` to match new naming conventions. 

1. **The Trap:** Go to the bottom of `lab_9.tf` and uncomment the `moved` block. Do NOT change anything else. 
2. **The Error:** Run `terraform plan`. You will get a fatal error: `Error: Moved object still exists`. This happens because you told Terraform to move the address, but the old resource name (`app_server`) is still physically typed out in your file!
3. **The Fix:** Go up to the EC2 resource block and rename it: change `resource "aws_instance" "app_server"` to `resource "aws_instance" "frontend_web_server"`.
4. **The Validation:** Run `terraform plan` again. Terraform will now output `Plan: 0 to add, 0 to change, 0 to destroy`, with a note that it intends to move the state address.
5. **The Apply:** Run `terraform apply -auto-approve` to officially write this new name into the `terraform.tfstate` file. 
6. **Verify the State:** Run `terraform state list`. Notice that `aws_instance.app_server` is gone, and `aws_instance.frontend_web_server` has seamlessly replaced it without destroying the actual AWS server!

#### Phase 4: Emergency CLI Operations
1. **Force a Replacement:** Imagine the EC2 instance got hacked or corrupted. The Terraform code hasn't changed, but you need a fresh server immediately. Run:
   `terraform apply -replace="aws_instance.frontend_web_server"`
2. **Generate the Dependency Graph:** See the explicit dependency you created between the EC2 instance and the S3 bucket:
   `terraform graph > architecture.dot`
   *(Pro-Tip: You can open the text inside `architecture.dot`, copy it, and paste it into a free online Graphviz visualizer like [GraphvizOnline](https://dreampuf.github.io/GraphvizOnline/) to see the actual flow chart).*