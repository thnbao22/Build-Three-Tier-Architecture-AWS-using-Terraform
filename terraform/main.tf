provider "aws" {
  region = local.location
}

locals {
  instance_type = "t2.micro"
  location      = "ap-southeast-1"
  envn          = "dev"
  vpc_cidr      = "10.10.0.0/24"
}

module "netwotking" {
  source            = "../modules/networking"
  vpc_cidr_block    = local.vpc_cidr
  access_ip         = var.access_ip
  private_sn_count  = 2
  public_sn_count   = 2
  db_subnet_group   = true
}

module "compute" {
  source            = "../modules/compute"
  instance_type     = local.instance_type
  ssh_key           = "test"
  lb_tg_name        = "demo_lb"
  key_name          = "Charles-lab"
  public_subnets    = module.netwotking.public_subnets
  private_subnets   = module.netwotking.private_subnets
  bastion_sg        = module.netwotking.bastion_sg
  frontend_app_sg   = module.netwotking.frontend_app_sg
  backend_app_sg    = module.netwotking.backend_app_sg
}

module "database" {
  source = "../modules/database"
  db_engine_version = "8.0"
  db_allocated_storage =10
  db_identifier = "db_)instance_demo"
  db_name = "admin"
  db_user_name = "charles"
  db_passwd = "passwd123"
  db_instance_class = "db.t2.micro"
  db_subnet_group_name = module.netwotking.rds_db_subnet_group[0]
  db_final_snapshot = true
  rds_sg = module.netwotking.rds_sg
}
