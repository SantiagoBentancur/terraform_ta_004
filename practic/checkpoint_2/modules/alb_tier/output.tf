output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value = aws_lb.alb_terraform.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.alb_terraform.arn
}

output "target_group_arn" {
  description = "ARN of the application target group used by the compute tier."
  value       = aws_lb_target_group.app.arn
}
