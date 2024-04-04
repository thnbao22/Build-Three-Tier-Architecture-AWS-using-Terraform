# Output the frontend auto scaling group
output "app_asg" {
  value = aws_autoscaling_group.three_tier_frontend_app
}

# Output the backend auto scaling group
output "app_backend_asg" {
  value = aws_autoscaling_group.three_tier_backend_app
}

