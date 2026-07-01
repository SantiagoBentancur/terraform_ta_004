
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


resource "aws_launch_template" "example" {
  name = "example"


  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }


  credit_specification {
    cpu_credits = "standard"
  }

  disable_api_stop        = true
  disable_api_termination = true

  ebs_optimized = true

  iam_instance_profile {
    name = "TODO"
  }

  image_id = data.aws_ami.latest_ubuntu.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_market_options {
    market_type = "spot - TO CHECK"
  }

  instance_type = var.type_instance[var.env]


  license_specification {
    license_configuration_arn = "arn:aws:license-manager:eu-west-1:123456789012:license-configuration:lic-0123456789abcdef0123456789abcdef"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  network_performance_options {
    bandwidth_weighting = "vpc-1"
  }

  network_interfaces {
    associate_public_ip_address = true
  }

  placement {
    availability_zone = "TODO"
  }

  ram_disk_id = "test"

  vpc_security_group_ids = ["TODO"]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "TODO"
    }
  }

}