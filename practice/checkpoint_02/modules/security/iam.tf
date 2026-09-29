resource "aws_iam_role" "app_ssm" {
  name = "${lower(var.env)}-${var.project}-app-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${lower(var.env)}-${var.project}-app-ssm-role"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "app_ssm_core" {
  role       = aws_iam_role.app_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app_ssm" {
  name = "${lower(var.env)}-${var.project}-app-ssm-profile"
  role = aws_iam_role.app_ssm.name

  tags = {
    Name        = "${lower(var.env)}-${var.project}-app-ssm-profile"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}
