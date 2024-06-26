# Get the DNS name of the Load Balancer
output "alb_dns" {
  value = aws_lb.three_tier_lb.dns_name
}

# Output the endpoint of the lb
output "lb_endpoint" {
  value = aws_lb.three_tier_lb.dns_name
}

# Output the name of the lb
output "lb_tg_name" {
  value = aws_lb_target_group.three_tier_tg.name
}

output "lb_tg" {
  value = aws_lb_target_group.three_tier_tg.arn
}
    
