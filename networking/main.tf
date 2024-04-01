# Provides a VPC resource
resource "aws_vpc" "three_tier_vpc" {
  # Define the IPv4 Block for the VPC
  cidr_block = var.vpc_cidr_block

  # (Optional) A boolean flag to enable/disable DNS hostnames in the VPC. 
  enable_dns_hostnames = true

  # (Optional) A boolean flag to enable/disable DNS support in the VPC. 
  enable_dns_support =  true

  tags = {
    "Name" = "three_tier_vpc"
  }
}

# Provides a resource to create a Internet Gateway
resource "aws_internet_gateway" "three_tier_InternetGateway" {
  # the vpc_id of your VPC that you want to attach Internet Gateway
  vpc_id = aws_vpc.three_tier_vpc.id

  tags = {
    "Name" = "three_tier_igw"
  }
  
}


data "aws_availability_zones" "available" {
  
}

# Define Public Subnets
resource "aws_subnet" "three_tier_public_subnet" {
    # (Required) the VPC ID
   vpc_id = aws_vpc.three_tier_vpc.id

   count = var.public_sn_count
   # CIDR block of the Public Subnet
   cidr_block = "10.10.${count.index}.0/24"

   # (Optional) Specify true to indicate that instances launched into the subnet should be assigned a public IP address.
   # Default is False
   map_public_ip_on_launch = true

   # Define AZ for the Public Subnet
   availability_zone = data.aws_availability_zones.available.name[count.index]

   tags = {
     "Name" = "three_tier_public_subnet_${count.index + 1}"
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
  route_table_id = aws_route_table.three_tier_public_rt.id

  # (Optional) the destination CIDR block.
  destination_cidr_block = "0.0.0.0/0"

  # (Optional) Identifier of a VPC internet gateway or a virtual private gateway.
  gateway_id = aws_internet_gateway.three_tier_InternetGateway.id
}

# Associate Public Subnet
resource "aws_route_table_association" "three_tier_public_associate" {
  # (Required) the ID of the routing table to associate with  
  route_table_id = aws_route_table.three_tier_public_rt.id
  
  count = var.public_sn_count
  # the Subnet ID to create an association
  subnet_id = aws_subnet.three_tier_public_subnet.id

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
  # ID of the EIP allocated to the selected NAT Gateway.
  allocation_id = aws_eip.three_tier_nat.id
    
  # (Optional) ID of subnet that the NAT Gateway resides in.      
  subnet_id = aws_subnet.three_tier_public_subnet.id
}

# Defines Private Subnets
resource "aws_subnet" "three_tier_private_subnet" {
   # (Required) the VPC ID
   vpc_id = aws_vpc.three_tier_vpc.id
   
   count = var.private_sn_count
   
   # CIDR block of the Private Subnet
   cidr_block = "10.10.${10 + count.index}.0/24"
   
   # (Optional) Specify false to indicate that instances launched into the subnet should not be assigned a public IP address.
   # Default is False
   map_public_ip_on_launch = false

   # Define AZ for the Public Subnet
   availability_zone = data.aws_availability_zones.available.name[count.index]

   tags = {
     "Name" = "three_tier_priavte_subnet_${count.index + 1}"
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
  route_table_id = aws_route_table.three_tier_private_rt.id
  
  count = var.private_sn_count
  # the Subnet ID to create an association
  subnet_id = aws_subnet.three_tier_private_subnet.id

}

# Define Private Subnet for Database
resource "aws_subnet" "three_tier_private_db" {
   vpc_id = aws_vpc.three_tier_vpc.id

   count = var.public_sn_count
   # CIDR block of the Public Subnet
   cidr_block = "10.10.${20 + count.index}.0/24"

   # (Optional) Specify false to indicate that instances launched into the subnet should be assigned a public IP address.
   # Default is False
   map_public_ip_on_launch = false

   # Define AZ for the Public Subnet
   availability_zone = data.aws_availability_zones.available.name[count.index]

   tags = {
     "Name" = "three_tier_private_db_${count.index + 1}"
   }
}

# Create Security Group


# Security Group for Bastion Host
resource "aws_security_group" "three_tier_bastion_sg" {
  name = "three_tier_bastion_sg"
  vpc_id = aws_vpc.three_tier_vpc.id
  
  #define inbound rules
  ingress = {

    # Define protocol for SSH into your Bastion Host
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_block  = var.cidr_block
  }
  # Define outbound rules
  egress = {
    # Default rules
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_block  = ["0.0.0.0/0"]
  }
}
