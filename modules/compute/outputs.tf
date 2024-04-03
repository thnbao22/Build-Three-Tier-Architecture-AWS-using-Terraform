output "app_asg" {
  value = aws_autoscaling_group.three_tier_frontend_app
}

output "app_backend_asg" {
  value = aws_autoscaling_group.three_tier_backend_app
}

