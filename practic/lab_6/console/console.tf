terraform {
  required_version = ">= 1.3.0"
}

locals {
  server_names       = ["web", "api", "db"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  services           = ["frontend", "backend", "worker"]
  users_enabled = {
    alice = true
    bob   = false
    carla = true
  }
  instances = [
    { name = "web-1", type = "t3.micro" },
    { name = "api-1", type = "t3.small" },
    { name = "db-1", type = "t3.medium" }
  ]
  nested_subnets = [
    ["subnet-a", "subnet-b"],
    ["subnet-c"],
    ["subnet-d", "subnet-e"]
  ]
  environment_services = {
    dev  = ["api", "worker"]
    prod = ["api", "worker", "frontend"]
  }
  names_with_empty_values = ["web", "", "api", "", "db"]
  regions_with_duplicates = ["us-east-1", "us-east-1", "eu-west-1", "ap-southeast-1", "eu-west-1"]
  allowed_ports_csv       = "80,443,8080"
  tag_words               = ["terraform", "aws", "practice"]
  default_tags = {
    project = "demo"
    owner   = "platform"
  }
  custom_tags = {
    owner = "santiago"
    env   = "dev"
  }
  servers = {
    web = { type = "t3.micro" }
    api = { type = "t3.small" }
  }
  security_groups = toset(["sg-aaa", "sg-bbb", "sg-ccc"])
  duplicate_names = ["api", "api", "web", "db"]
  config_object   = { region = "us-east-1", env = "dev" }
  ports           = [22, 80, 443, 8080, 9000]
  security_group_rules = [
    { protocol = "tcp", port = 80 },
    { protocol = "tcp", port = 443 },
    { protocol = "udp", port = 53 }
  ]
  team_roles = {
    alice = ["admin", "developer"]
    bob   = ["viewer"]
    carla = ["developer", "viewer"]
  }
}
