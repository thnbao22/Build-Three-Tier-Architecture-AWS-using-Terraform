
data "aws_ssm_parameter" "three_tier_ami" {
  name = "ssm_three_tier"
}

# Launch Template for Bastion Host
# Provides an EC2 launch template resource.
# Before you can create an Auto Scaling Group, you need to create and configure the launch template
# Explanation
resource "aws_launch_template" "three_tier_bastion" {
  
  # name_prefix: (Optional) Creates a unique name beginning with the specified prefix.
  name_prefix = "three_tier_bastion"

  # In your launch template you need to specify an instance type. Example: t2.micro
  instance_type = var.instance_type

  # The Image Id you want to launch the instance. Example: Amazon Linux 2023 AMI, ...
  image_id = data.aws_ssm_parameter.three_tier_ami.value
  
  # Becasue we launch the bastion host in Public Subent in a VPC so we gonna use the attribute vpc_security_group_ids instead of security_group_names
  vpc_security_group_ids = [var.bastion_sg]

  # The key name to use for the instance
  key_name = var.key_name

  tags = {
    Name = "three_tier_bastion"
  }
}                 

# Define Auto Scaling Group for Bastion Host
resource "aws_autoscaling_group" "three_tier_bastion" {
  # Name of the Auto Scaling Group
  name = "three_tier_bastion"

  # (Required) Minimum size of the Auto Scaling Group 
  min_size = 1

  # (Required) Maximum size of the Auto Scaling Group
  max_size = 1

  # Define the number of EC2 instances that should be running in the groups
  desired_capacity = 1

  # List of subnet IDs to launch resources in. Here we launch instance in Public Subnets
  vpc_zone_identifier = var.public_subnets

  # Note: Either id or name must be specified
  launch_template {
    # (Optimal) Id of the launch Template we use for Bastion Host
    id = aws_launch_template.three_tier_bastion.id
    
    # (Optimal) Template version 
    version = "$Latest"
  }
}

# Define Launch template for FE app Auto Scaling Group
resource "aws_launch_template" "three_tier_frontend_app" {
  
  # name_prefix: (Optional) Creates a unique name beginning with the specified prefix.
  name_prefix = "three_tier_frontend_app"
  
  # In your launch template you need to specify an instance type. Example: t2.micro
  instance_type = var.instance_type

  # The Image Id you want to launch the instance. Example: Amazon Linux 2023 AMI, ...
  image_id = data.aws_ssm_parameter.three_tier_ami.value

  # Becasue we launch the front end app in Public Subent in a VPC so we gonna use the attribute vpc_security_group_ids instead of security_group_names
  vpc_security_group_ids = [var.frontend_app_sg]

  # The key name to use for the instance
  key_name = var.key_name

  # Instead of SSH into the EC2 instance, you can install apache server before you launch the instance.
  # So that you don't waste time to ssh into instance and run the script to install apache server
  # Explanation about the attribute "user_data" on Harshicop: (Optimal) The base64-encoded user data to provide when launching the instance.
  
  user_data = filebase64("install_apache.sh")

  tags = {
    Name = "three_tier_frontend_app" 
  }
}                 

# The attribute aws_alb_target_group provides information about a Load Balancer Target Group
data "aws_alb_target_group" "three_tier_tg" {
  name = var.lb_tg_name
  
}

# Define Auto Scaling Group for FE app
resource "aws_autoscaling_group" "three_tier_frontend_app" {
  # Name of the Auto Scaling Group
  name = "three_tier_frontend_app"
  
  # (Required) Minimum size of the Auto Scaling Group 
  min_size = 2
  
  # (Required) Maximum size of the Auto Scaling Group
  max_size = 3
  
  # Define the number of EC2 instances that should be running in the groups
  desired_capacity = 3
  
  # List of subnet IDs to launch resources in. Here we launch the frontend app in Public Subnets
  vpc_zone_identifier = var.public_subnets


  target_group_arns = [data.aws_alb_target_group.three_tier_frontend_app.arn]
  
  launch_template {
    id = aws_launch_template.three_tier_frontend_app.id
    version = "$Latest"
  } 
}

resource "aws_launch_template" "three_tier_backend_app" {
  
  # name_prefix: (Optional) Creates a unique name beginning with the specified prefix.
  name_prefix = "three_tier_backend_app"
  
  # In your launch template you need to specify an instance type. Example: t2.micro
  instance_type = var.instance_type

  # The Image Id you want to launch the instance. Example: Amazon Linux 2023 AMI, ...
  image_id = data.aws_ssm_parameter.three_tier_ami.value
  
  vpc_security_group_ids = [var.backend_app_sg]

  # The key name to use for the instance
  key_name = var.key_name

  user_data = filebase64("install_node.sh")

  tags = {
    Name = "three_tier_backend_app" 
  }
}             


resource "aws_autoscaling_group" "three_tier_backend_app" {
  name = "three_tier_backend_app"
  min_size = 2
  max_size = 3
  desired_capacity = 2
  vpc_zone_identifier = var.private_subnets


  target_group_arns = [data.aws_alb_target_group.three_tier_backend_app.arn]
  
  launch_template {
    id = aws_launch_template.three_tier_backend_app.id
    version = "$Latest"
  } 
}