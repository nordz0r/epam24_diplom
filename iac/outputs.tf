# Outputs
output "db-prod" {
  value = module.rds.db_prod
  description = "DB endpoint"
}

output "db-dev" {
  value = module.rds.db_dev
  description = "DB endpoint"
}

output "eks_cluster_name" {
  value       = module.eks.eks_cluster_name
  description = "EKS cluster name"
}
