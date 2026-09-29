
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-${var.ubuntu_codename}-${var.ubuntu_version}-amd64-server-*"]

  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]

  }

}


resource "aws_launch_template" "web_app" {
  name = "${lower(var.env)}-${var.project}-aws-launch-template"

  tags = {
    Name        = "${lower(var.env)}-${var.project}-launch-template"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }


  credit_specification {
    cpu_credits = "standard"
  }

  disable_api_stop        = true
  disable_api_termination = true

  image_id = data.aws_ami.latest_ubuntu.id

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = var.type_instance[var.env]

  monitoring {
    enabled = true
  }

  # EC2 instance will live in my private subnets
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.app_security_group_ids
  }


  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.env}"
      Environment = var.env
      Project     = var.project
      ManagedBy   = "Terraform"
    }
  }

}


resource "aws_autoscaling_group" "app_scaling" {
  name                      = "${lower(var.env)}-${var.project}-asg"
  max_size                  = var.auto_scaling_set_up[var.env].max_size
  min_size                  = var.auto_scaling_set_up[var.env].min_size
  health_check_grace_period = var.auto_scaling_set_up[var.env].health_check_grace_period
  health_check_type         = var.auto_scaling_set_up[var.env].health_check_type
  desired_capacity          = var.auto_scaling_set_up[var.env].desired_capacity
  force_delete              = true
  vpc_zone_identifier       = var.app_subnet_ids
  target_group_arns         = var.target_group_arns

  launch_template {
    id      = aws_launch_template.web_app.id
    version = aws_launch_template.web_app.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${lower(var.env)}-${var.project}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.env
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }


}
