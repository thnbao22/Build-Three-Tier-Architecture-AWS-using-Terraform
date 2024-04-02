# Provides an SSM Parameter data source.
data "aws_ssm_parameter" "three_tier_ami" {
  name = "/production/ami"
}

# Creates a PEM (and OpenSSH) formatted private key.
resource "tls_private_key" "main" {
  # (Required) Name of the algorithm to use when generating the private key.
  algorithm = "RSA"
  # When algorithm is RSA, the size of the generated RSA key, in bits (default: 2048).
  rsa_bits  = 2048
}

# To access to the EC2 instance, you need to have a keypair
# Provides an EC2 keypair resource. A key pair is used to control login access to EC2 instances.
resource "aws_key_pair" "main" {
  # (Optional) The name for the key pair.
  key_name    = var.ssh_key
  # (Required) the public key material
  public_key  = tls_private_key.main.public_key_openssh
}

# To store the public key in your local machine, you can use the resource local_file
resource "local_file" "ssh_key" {
  # The path to the file that will be created.
  filename        = "${var.ssh_key}-pem"
  
  # Permissions to set for the output file (before umask), expressed as string in numeric notation.   
  # Default value is "0777" 
  file_permission = tls_private_key.main.private_key_openssh

  content         = tls_private_key.main.private_key_openssh
  
}

# Launch Template for Bastion Host
# Provides an EC2 launch template resource.
# Before you can create an Auto Scaling Group, you need to create and configure the launch template
resource "aws_launch_template" "three_tier_bastion" {  
  # name_prefix: (Optional) Creates a unique name beginning with the specified prefix.
  name_prefix             = "three_tier_bastion"

  # In your launch template you need to specify an instance type. Example: t2.micro
  instance_type           = var.instance_type

  # The Image Id you want to launch the instance. Example: Amazon Linux 2023 AMI, ...
  image_id                = data.aws_ssm_parameter.three_tier_ami.value
  
  # Becasue we launch the bastion host in Public Subent in a VPC so we gonna use the attribute vpc_security_group_ids instead of security_group_names
  vpc_security_group_ids  = [var.bastion_sg]

  # The key name to use for the instance
  key_name                = var.key_name

  tags = {
    Name = "three_tier_bastion"
  }
}                 

# Define Auto Scaling Group for Bastion Host
resource "aws_autoscaling_group" "three_tier_bastion" {
  # Name of the Auto Scaling Group
  name                = "three_tier_bastion"

  # (Required) Minimum size of the Auto Scaling Group 
  min_size            = 1

  # (Required) Maximum size of the Auto Scaling Group
  max_size            = 1

  # Define the number of EC2 instances that should be running in the groups
  desired_capacity    = 1

  # List of subnet IDs to launch resources in. Here we launch instance in Public Subnets
  vpc_zone_identifier = var.public_subnets

  # Note: Either id or name must be specified
  launch_template {
    # (Optional) Id of the launch Template we use for Bastion Host
    id                = aws_launch_template.three_tier_bastion.id
    
    # (Optional) Template version 
    version           = "$Latest"
  }
}

# Define Launch template for FE app Auto Scaling Group
resource "aws_launch_template" "three_tier_frontend_app" {
  
  # name_prefix: (Optional) Creates a unique name beginning with the specified prefix.
  name_prefix             = "three_tier_frontend_app"
  
  # In your launch template you need to specify an instance type. Example: t2.micro
  instance_type           = var.instance_type

  # The Image Id you want to launch the instance. Example: Amazon Linux 2023 AMI, ...
  image_id                = data.aws_ssm_parameter.three_tier_ami.value

  # Becasue we launch the front end app in Public Subent in a VPC so we gonna use the attribute vpc_security_group_ids instead of security_group_names
  vpc_security_group_ids  = [var.frontend_app_sg]

  # The key name to use for the instance
  key_name                = var.key_name

  # Instead of SSH into the EC2 instance, you can install apache server before you launch the instance.
  # So that you don't waste time to ssh into instance and run the script to install apache server
  # Explanation about the attribute "user_data" on Harshicop: (Optional) The base64-encoded user data to provide when launching the instance.
  
  user_data               = filebase64("install_apache.sh")

  tags = {
    Name = "three_tier_frontend_app" 
  }
}                 

# The attribute aws_alb_target_group provides information about a Load Balancer Target Group
# Retrive the name of the alb target group
data "aws_alb_target_group" "three_tier_tg" {
  name = var.lb_tg_name
  
}

# Define Auto Scaling Group for FE app
resource "aws_autoscaling_group" "three_tier_frontend_app" {
  # Name of the Auto Scaling Group
  name                = "three_tier_frontend_app"
  
  # (Required) Minimum size of the Auto Scaling Group 
  min_size            = 2
  
  # (Required) Maximum size of the Auto Scaling Group
  max_size            = 3
  
  # Define the number of EC2 instances that should be running in the groups
  desired_capacity    = 3
  
  # List of subnet IDs to launch resources in. Here we launch the frontend app in Public Subnets
  vpc_zone_identifier = var.public_subnets

  # Set of aws_alb_target_group ARNs, for use with Application or Network Load Balancing
  target_group_arns   = [data.aws_alb_target_group.three_tier_frontend_app.arn]
  
  launch_template {
    id      = aws_launch_template.three_tier_frontend_app.id
    version = "$Latest"
  } 
}

# Define launch Template for BE app
resource "aws_launch_template" "three_tier_backend_app" {
  
  # name_prefix: (Optional) Creates a unique name beginning with the specified prefix.
  name_prefix             = "three_tier_backend_app"
  
  # In your launch template you need to specify an instance type. Example: t2.micro
  instance_type           = var.instance_type

  # The Image Id you want to launch the instance. Example: Amazon Linux 2023 AMI, ...
  image_id                = data.aws_ssm_parameter.three_tier_ami.value
  
  vpc_security_group_ids  = [var.backend_app_sg]

  # The key name to use for the instance
  key_name                = var.key_name

  user_data               = filebase64("install_node.sh")

  tags = {
    Name = "three_tier_backend_app" 
  }
}             

# define Auto Scaling Group for BE app
resource "aws_autoscaling_group" "three_tier_backend_app" {
  # Name of the Auto Scaling Group
  name                = "three_tier_backend_app"

  # (Required) Minimum size of the Auto Scaling Group
  min_size            = 2

  # (Required) Maximum size of the Auto Scaling Group
  max_size            = 3
  
  # The number of EC3 instances should be running in the group
  desired_capacity    = 2

  # The VPC zone identifier
  vpc_zone_identifier = var.private_subnets

  # Set of aws_alb_target_group ARNs, for use with Application or Network Load Balancing
  target_group_arns   = [data.aws_alb_target_group.three_tier_backend_app.arn]
  
  # Decide which template you want your Auto Scaling Group to use
  launch_template {
    # (Optional) ID of the Launch Template
    id      = aws_launch_template.three_tier_backend_app.id
    # Template version. Can be &Default or & Latest
    version = "$Latest"
  } 
}