# Provides a Load Balancer Resoures
resource "aws_lb" "three_tier_lb" {
  # Define the type of tour load Balancer
  load_balancer_type  = "application"

  # The name of your Load Balancer
  name                = "three_tier_lb"
  
  # A list of sg IDs to assign to the LB
  # Valid for type application or network
  security_groups     = [var.lb_sg]

  # A list of Subnet IDs to attach to the LB
  subnets             = var.public_subnets

  # the time in seconds that the connection is allowed to be idle
  # Only valid for Load Balancers type of application
  idle_timeout        = 400

  depends_on          = [ var.app_sg ]
}

# Provides a Target Group resource for use with Load Balancer resources
resource "aws_lb_target_group" "three_tier_tg" {
  # Define name of the Target Group
  name      = "three_tier_lb_tg"

  # Port on which targets receive traffic, unless overridden when registering a specific target.
  # Required when target_group is instance, ip or alb.
  port      = var.port

  # Protocol to use for routing traffic to the target.
  # Example: HTTP, SSH, ...
  protocol  = var.protocol

  # Identifier of the VPC in which to create the target group 
  vpc_id    = var.vpc_id


  
  lifecycle {
    ignore_changes = [ name ]
    create_before_destroy = true
  }
}

# Provides a Load Balancer Listener resource.
# We already know that listener is a part of Load Balancer Target Group
resource "aws_lb_listener" "three_tier_lb" {
  # Required: ARN of the load balancer
  load_balancer_arn   = aws_lb_target_group.three_tier_lb.arn
  
  # (Optional) Port on which the load balancer is listening
  port                = var.port
  # (Optional) Protocol for connections from clients to the load balancer. 
  protocol            = var.protocol

  # Required: Configuration block for default actions
  default_action {
    # Required: Type of routing action.
    type              = "forward"

    # Optional: ARN of the Target Group to which to route traffic.
    target_group_arn  = aws_lb_target_group.three_tier_lb.arn
  }
}
