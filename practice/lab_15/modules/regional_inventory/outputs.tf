output "availability_zones" {
  value = {
    primary   = data.aws_availability_zones.available_east.names
    secondary = data.aws_availability_zones.available_west.names
  }
}