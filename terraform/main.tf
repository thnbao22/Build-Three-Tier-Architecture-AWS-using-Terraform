# Use the Amazon Web Services (AWS) provider to interact with the many resources supported by AWS.
provider "aws" {
  # Define Region from local values
  region = local.location
}

# Define local values u want to use
locals {
  # Your instance type. t2.micro is free tier
  instance_type = "t2.micro"
  # Location of your region
  location      = "ap-southeast-1"
  # Define your enviroment
  envn          = "dev"
  # Your VPC cidr block. Here, I choose 10.10.0.0/24
  vpc_cidr      = "10.10.0.0/24"
}

# Modules are containers for multiple resources that are used together.

## Define module for networking
module "netwotking" {
  source            = "../modules/networking"
  # Define cidr block for your VPC from local values
  vpc_cidr_block    = local.vpc_cidr
  access_ip         = var.access_ip
  private_sn_count  = 2
  public_sn_count   = 2
  # The db subnet group will be created
  db_subnet_group   = true
}

## Define module for compute
module "compute" {
  source            = "../modules/compute"
  # Define instance type from your local values
  instance_type     = local.instance_type
  ssh_key           = "test"
  lb_tg_name        = "demo_lb"
  key_name          = "Charles-lab"

  # These attribute below can be defined after you successufully createed resources in your VPC
  # Because of that, you need to take the output from the module networking
  public_subnets    = module.netwotking.public_subnets
  private_subnets   = module.netwotking.private_subnets
  bastion_sg        = module.netwotking.bastion_sg
  frontend_app_sg   = module.netwotking.frontend_app_sg
  backend_app_sg    = module.netwotking.backend_app_sg
}

## Define module for database
module "database" {
  source                = "../modules/database"
  db_engine_version     = "8.0"
  db_identifier         = "db_instance_demo"
  db_user_name          = "charles"
  db_passwd             = "passwd123"
  db_instance_class     = "db.t2.micro"
  db_allocated_storage  = 10
  db_subnet_group_name  = module.netwotking.rds_db_subnet_group[0]
  db_name               = "admin"
  db_final_snapshot     = true
  rds_sg                = module.netwotking.rds_sg
}
