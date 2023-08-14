output "ecr-repository" {
  value = module.create-repository.ecr-address
}

output "rds-endpoint" {
  value = module.create-database.database-address
}

output "execution-role-arn" {
  value = module.task-execution-role.execution-role-arn
}

output "monitoring_ip" {
  value = module.create-monitoring.ec2_ip
}

output "monitoring_address" {
  value = module.create-monitoring.monitoring_address
}

output "elb-dns" {
  value = module.create-cluster.elb-dns
}
