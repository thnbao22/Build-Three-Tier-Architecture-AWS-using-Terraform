# Output the endpoint of the db instance
output "db_endpoint" {
    value = aws_db_instance.three_tier_db.endpoint
}