# Launch Template for Bastion Host



data "aws_ssm_parameter" "three_tier_ami" {
  name = "ssm_three_tier"
}

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
  
  vpc_security_group_ids = [var.bastion_sg]

  # The key name to use for the instance
  key_name = var.key_name

  tags = {
    Name = "three_tier_bastion"
  }
}                 


resource "aws_autoscaling_group" "three_tier_bastion" {
  name = "three_tier_bastion"
  min_size = 1
  max_size = 1
  desired_capacity = 1
  vpc_zone_identifier = var.public_subnets
  launch_template {
    id = aws_launch_template.three_tier_bastion.id
    version = "$Latest"
  }
}




# Define Launch template for app Auto Scaling Group
resource "aws_launch_template" "three_tier_app" {
  
  # name_prefix: (Optional) Creates a unique name beginning with the specified prefix.
  name_prefix = "three_tier_app"
  
  # In your launch template you need to specify an instance type. Example: t2.micro
  instance_type = var.instance_type

  # The Image Id you want to launch the instance. Example: Amazon Linux 2023 AMI, ...
  image_id = data.aws_ssm_parameter.three_tier_ami.value
  
  vpc_security_group_ids = [var.frontend_app_sg]

  # The key name to use for the instance
  key_name = var.key_name

  # Instead of SSH into the EC2 instance, you can install apache server before you launch the instance.
  # So that you don't waste time to ssh into instance and run the script to install apache server
  # Explanation about the attribute "user_data" on Harshicop: (Optimal) The base64-encoded user data to provide when launching the instance.
  
  user_data = filebase64("install_apache.sh")

  tags = {
    Name = "three_tier_app" 
  }
}                 

data "aws_alb_target_group" "three_tier_tg" {
  name = var.lb_tg_name
  
}