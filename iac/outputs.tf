# Outputs
output "db_host" {
  value = module.rds.db_host
  description = "DB host"
}

output "db" {
  value = module.rds.db
  description = "DB endpoint"
}


output "eks_cluster_name" {
  value       = module.eks.eks_cluster_name
  description = "EKS cluster name"
}


# output "db_host" {
#   value       = aws_db_instance.mysql.address
#   description = "DB host"
# }

# output "db" {
#   value       = aws_db_instance.mysql.endpoint
#   description = "DB endpoint"
# }

# output "db_name" {
#   value       = aws_db_instance.postgresql.name
#   description = "DB name"
# }

# output "db_user" {
#   value       = aws_db_instance.postgresql.username
#   description = "DB user"
# }

# output "db_password" {
#   value       = aws_db_instance.postgresql.password
#   description = "DB password"
#   sensitive   = true
# }

# output "eks_cluster_name" {
#   value       = aws_eks_cluster.eks.name
#   description = "EKS cluster name"
# }