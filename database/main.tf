resource "aws_db_instance" "three_tier_db" {
  # The amount of allocated storage
  # The Minimum value is 100 Gib and the maximum value is 65,536 Gib
  allocated_storage         = var.db_allocated_storage
  
  # Define the RDS instance you want to choose
  instance_class            = var.db_instance_class
  
  # Specify the db engine you want to use
  engine                    = "mysql"

  # The engine version you want to use for your db instance
  # Exmaple: MySQL 8.0.35, ...
  engine_version            = var.db_engine_version
 
  # The database name
  db_name                   = var.db_name

  # the name of RDS instance
  # This attribute is DB cluster identifier when you create RDS in the Console
  identifier                = var.db_identifier

  # The master username for the database. By default, admin is your master username  
  username                  = var.db_user_name

  # Password for master DB user
  # Cannot be set if manage_master_user_password is set to true
  password                  = var.db_passwd 

  # Name of DB subnet Group
  # DB instance will be created in the VPC associated with the DB subnet group
  db_subnet_group_name      = var.db_subnet_group_name 
  
  # Determines whether a final DB snapshot is created before the DB instance is deleted.
  # If true is specified, no Snapshot is created
  # If false is specified, a DB Snapshot is created before the DB instance is deleted
  skip_final_snapshot       = var.db_final_snapshot

  # Because our DB instance will run in the private subnet in the VPC so need to associate a security group
  vpc_security_group_ids    = [var.rds_sg]
  
  tags = {
    "Name" =  "three_tier_db"
  }
}