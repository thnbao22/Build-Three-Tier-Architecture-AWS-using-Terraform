# Output the id of the VPC
output "vpc_id" {
    value = aws_vpc.three_tier_vpc.id
}
# Output the name of db subnet group
output "db_subnet_group_name" {
    value = aws_db_subnet_group.three_tier_db_subnet_group.*.name
}
# Output the id of db subnet_group
output "rds_db_subnet_group" {
    value = aws_db_subnet_group.three_tier_db_subnet_group.*.Id
}
# Output the id of RDS SG
output "rds_sg" {
    value = aws_security_group.three_tier_db_sg.id
}
# Output the id of Bastion Host SG
output "bastion_sg" {
    value = aws_security_group.three_tier_bastion_sg
}

# Output the id of FE SG
output "frontend_app_sg" {
    value = aws_security_group.three_tier_frontend_sg.id
}
# Output the id of BE SG
output "backend_app_sg" {
    value = aws_security_group.three_tier_backend_sg.id
}
# Output the id of LB SG
output "lb_sg" {
    value = aws_security_group.three_tier_lb_sg.id
}
# Output the id of all your public subnets
output "public_subnets" {
    value = aws_subnet.three_tier_public_subnet.*.id
}
# Output the id of all your private subnets
output "private_subnets" {
    value = aws_subnet.three_tier_private_subnet.*.id 
}