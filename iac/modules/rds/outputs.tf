# RDS Endpoint
output "db_host" {
  value       = aws_db_instance.mysql.address
  description = "DB host"
}

output "db" {
  value       = aws_db_instance.mysql.endpoint
  description = "DB endpoint"
}
