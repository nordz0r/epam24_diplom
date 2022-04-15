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
