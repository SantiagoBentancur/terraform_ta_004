output "sg_alb_id" {
  value = aws_security_group.alb.id
}

output "sg_db_id" {
  value = aws_security_group.db.id
}

output "sg_app_id" {
  value = aws_security_group.app.id
}

output "app_instance_profile_name" {
  description = "Name of the IAM instance profile attached to application EC2 instances."
  value       = aws_iam_instance_profile.app_ssm.name
}
