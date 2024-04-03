# Provides a VPC resource
resource "aws_vpc" "three_tier_vpc" {
  # Define the IPv4 Block for the VPC
  cidr_block            = var.vpc_cidr_block

  # (Optional) A boolean flag to enable/disable DNS hostnames in the VPC. 
  enable_dns_hostnames  = true

  # (Optional) A boolean flag to enable/disable DNS support in the VPC. 
  enable_dns_support    = true

  tags = {
    "Name"              = "three_tier_vpc"
  }
}

# Provides a resource to create a Internet Gateway
resource "aws_internet_gateway" "three_tier_InternetGateway" {
  # the vpc_id of your VPC that you want to attach Internet Gateway
  vpc_id    = aws_vpc.three_tier_vpc.id

  tags = {
    "Name"  = "three_tier_igw"
  }
  
}


data "aws_availability_zones" "available" {
  
}

# Define Public Subnets
resource "aws_subnet" "three_tier_public_subnet" {
    # (Required) the VPC ID
   vpc_id                   = aws_vpc.three_tier_vpc.id

   count                    = var.public_sn_count
   # CIDR block of the Public Subnet
   cidr_block               = "10.10.${count.index}.0/24"

   # (Optional) Specify true to indicate that instances launched into the subnet should be assigned a public IP address.
   # Default is False
   map_public_ip_on_launch  = true

   # Define AZ for the Public Subnet
   availability_zone        = data.aws_availability_zones.available.name[count.index]

   tags = {
     "Name"                 = "three_tier_public_subnet_${count.index + 1}"
   }  
}

# Define a Public Route Table for public subnet
resource "aws_route_table" "three_tier_public_rt" {
  # (Required) The VPC ID
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name = "three_tier_public_rt"
  }
}

#Provides a resource to create a routing table entry (a route) in a VPC routing table.
resource "aws_route" "public_subnet_rt" {
  # (Required) the ID of the routing table
  route_table_id          = aws_route_table.three_tier_public_rt.id

  # (Optional) the destination CIDR block.
  # 0.0.0.0/0 represents the Internet
  destination_cidr_block  = "0.0.0.0/0"

  # (Optional) Identifier of a VPC internet gateway or a virtual private gateway.
  # So the instance in public subent can access internet via Internet Gateway
  gateway_id              = aws_internet_gateway.three_tier_InternetGateway.id
}

# Associate Public Subnet
resource "aws_route_table_association" "three_tier_public_associate" {
  # (Required) the ID of the routing table to associate with  
  route_table_id  = aws_route_table.three_tier_public_rt.id
  
  count           = var.public_sn_count
  # the Subnet ID to create an association
  subnet_id       = aws_subnet.three_tier_public_subnet.id
}

# Provides an Elastic IP resource.
# Before you can create a NAT Gateway, you need to allocate Elastic IP addresses first.
resource "aws_eip" "three_tier_nat" {
  # the domain attribute indicates if this EIP is for use in VPC
  domain = "vpc"
}

# Provides a resource to create a VPC NAT Gateway.
resource "aws_nat_gateway" "three_tier_nat" {
  # When you create a NAT Gateway, you gonna allocate Elastic IP address
  # (Optional) ID of the EIP allocated to the selected NAT Gateway.
  allocation_id = aws_eip.three_tier_nat.id
    
  # (Optional) ID of subnet that the NAT Gateway resides in.      
  subnet_id     = aws_subnet.three_tier_public_subnet.id
}

# Defines Private Subnets
resource "aws_subnet" "three_tier_private_subnet" {
   # (Required) the VPC ID
   vpc_id                   = aws_vpc.three_tier_vpc.id
   
   count                    = var.private_sn_count
   
   # CIDR block of the Private Subnet
   cidr_block               = "10.10.${10 + count.index}.0/24"
   
   # (Optional) Specify false to indicate that instances launched into the subnet should not be assigned a public IP address.
   # Default is False
   map_public_ip_on_launch  = false

   # Define AZ for the Public Subnet
   availability_zone        = data.aws_availability_zones.available.name[count.index]

   tags = {
     "Name"                 = "three_tier_priavte_subnet_${count.index + 1}"
   }  
}

# Define a Private Route Table for private subnet
resource "aws_route_table" "three_tier_private_rt" {
  # (Required) The VPC ID
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name = "three_tier_private_rt"
  }
}

# Associate Private Subnet
resource "aws_route_table_association" "three_tier_private_associate" {
  # (Required) the ID of the routing table to associate with  
  route_table_id  = aws_route_table.three_tier_private_rt.id
  
  count           = var.private_sn_count
  # the Subnet ID to create an association
  subnet_id       = aws_subnet.three_tier_private_subnet.id

}

# Define Private Subnet for Database
resource "aws_subnet" "three_tier_private_db" {
   vpc_id                   = aws_vpc.three_tier_vpc.id

   count                    = var.public_sn_count
   # CIDR block of the Public Subnet
   cidr_block               = "10.10.${20 + count.index}.0/24"

   # (Optional) Specify false to indicate that instances launched into the subnet should be assigned a public IP address.
   # Default is False
   map_public_ip_on_launch  = false

   # Define AZ for the Public Subnet
   availability_zone        = data.aws_availability_zones.available.name[count.index]

   tags = {
     "Name"                 = "three_tier_private_db_${count.index + 1}"
   }
}

# Create Security Group
# Security Group is stateful so it denies all inbound rules and allowws all outbound rules


## Security Group for Bastion Host
resource "aws_security_group" "three_tier_bastion_sg" {
  # Name of the Security group for Bastion Host
  name          = "three_tier_bastion_sg"

  # Add description for Bastion SG
  description   = "Allow SSH into Bastion Host"
  vpc_id        = aws_vpc.three_tier_vpc.id
  
  ## define inbound rules for Bastion SG
  ingress = {

    ### Define protocol for SSH into your Bastion Host
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_block  = var.access_ip
  }

  ## Define outbound rules for Bastion SG
  egress = {

    ### Default rules
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_block  = ["0.0.0.0/0"]
  }
}

# Define Security Group for Load Balancer
resource "aws_security_group" "three_tier_lb_sg" {
  # Name of the Load Balancer SG
  name          = "three_tier_lb_sg"

  vpc_id        = aws_vpc.three_tier_vpc.id

  ## Define inbound rules for LB SG
  ingress = {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_block  = ["0.0.0.0/0"]
  } 

  ## Define outbound rules for LB SG
  egress = {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_block  = ["0.0.0.0/0"]
  }
}

# Define local value
locals {
  # Port 80: HTTP
  port_in_80 = [
    80
  ]
  # Port 22: SSH
  port_in_22 = [
    22
  ]
  # The MySQL port is 3306 by default
  port_in_3306 = [
    3306
  ]
}

## Security Group for FE app
resource "aws_security_group" "three_tier_frontend_sg" {
  # Name of the Security group for Frontend app
  name          = "three_tier_frontend_sg"

  # Add desciption for frontend SG
  description   = "Allow SSH from Bastion Host"
  vpc_id        = aws_vpc.three_tier_vpc.id 

  # With dynamic, we can easily configure more ingress rules without creating new resources
  # The for_each argument provides the complex value to iterate over.
  
  # Ingress rules for Bastion Host SG
  dynamic "ingress" {
    for_each = toset(local.port_in_22)
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"

      # List of Security Groups. Here is the Bastion SG
      security_groups = [aws_security_group.three_tier_bastion_sg.id]
    }
  }

  # Ingress rules for Lb SG using port 80
  dynamic "ingress" {
    for_each = toset(local.port_in_80)
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"

      # List of Security Groups. Here is the LB SG
      security_groups = [aws_security_group.three_tier_lb_sg.id]
    }      
  }

  # Egress rules for FE SG
  egress = {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_block        = ["0.0.0.0/0"]
  }
}

# Security Group for BE app
resource "aws_security_group" "three_tier_backend_sg" {
  name    = "three_tier_backend_sg"
  vpc_id  = aws_vpc.three_tier_vpc.id 

  # Ingress rules for FE SG using port 80
  dynamic "ingress" {
    for_each = toset(local.port_in_80)
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"

      # Choose the FE SG
      security_groups = [aws_security_group.three_tier_frontend_sg.id]
    }      
  }
  # Egress rules for BE SG
  egress = {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_block        = ["0.0.0.0/0"]
  }
}

# Provides an RDS DB subnet group resource
resource "aws_db_subnet_group" "three_tier_db_subnet_group" {
  # If count is true that means the subnet group will be created otherwise it will not be created
  count       = var.db_subnet_group == true ? 1 : 0
  # Name of the db subnet group
  name        = "three_tier_db_subnet_group"

  # (Required) A list of VPC subnet IDs.
  subnet_ids  = [aws_subnet.three_tier_private_db[0].id, aws_subnet.three_tier_private_db[1].id]
  tags = {
    Name      = "SubnetGroupDB"
  }
}

## Security Group for RDS MySQL
resource "aws_security_group" "three_tier_db_sg" {
  # name of the DB SG
  name    = "three_tier_db_sg"
  vpc_id  = aws_vpc.three_tier_vpc

  # ingress rule for BE SG
  dynamic "ingress" {
    for_each = toset(local.port_in_3306)
    content {
      from_port         = ingress.value
      to_port           = ingress.value
      protocol          = "tcp"
      security_groups   = [aws_security_group.three_tier_backend_sg.id]
    }
  }

  egress = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_block  = ["0.0.0.0/0"]
  }
}