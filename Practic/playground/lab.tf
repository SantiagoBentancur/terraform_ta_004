provider "aws" {
  region = "us-east-1"
}

# 1. The "Production Database" (Protected)
resource "aws_s3_bucket" "prod_db_backup" {
  bucket_prefix = "critical-db-backup-"

#   lifecycle {
#     # Hard safety lock to prevent accidental deletion
#     prevent_destroy = true
#   }
}

# 2. The App Server (Ignoring Manual Changes)
resource "aws_instance" "frontend_web_server" {
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
moved {
  from = aws_instance.app_server
  to   = aws_instance.frontend_web_server
}