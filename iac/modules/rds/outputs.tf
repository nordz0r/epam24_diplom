# RDS Endpoint
output "db_prod" {
  value       = aws_db_instance.mysql_prod.endpoint
  description = "DB endpoint"
}

output "db_dev" {
  value       = aws_db_instance.mysql_dev.endpoint
  description = "DB endpoint"
}
