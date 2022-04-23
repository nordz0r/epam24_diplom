# RDS Endpoint
output "db_prod" {
  value       = aws_db_instance.mysql_prod.address
  description = "DB endpoint"
}

output "db_dev" {
  value       = aws_db_instance.mysql_dev.address
  description = "DB endpoint"
}
