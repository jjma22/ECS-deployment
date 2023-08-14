# module "create-repository" {
#   source = "./module/repository"
# }

# module "create-network" {
#   source = "./module/network"
# }

# module "create-database" {
#   source               = "./module/database"
#   db_subnet_group_name = module.create-network.private-subnet-group-name
#   vpc_id               = module.create-network.vpc_id
# }

module "task-execution-role" {
  source = "./module/task-execution"
}


# module "create-cluster" {
#   source         = "./module/cluster"
#   vpc_id         = module.create-network.vpc_id
#   ec2-subnet     = module.create-network.public-subnet-group-name
#   public_subnets = module.create-network.public-subnet-group-name
#   repository_url = module.create-repository.ecr-address
# }

# module "create-monitoring" {
#   source         = "./module/monitoring"
#   public_subnets = module.create-network.public-subnet-group-name
#   vpc_id         = module.create-network.vpc_id
#   user-data      = file("${path.module}/user-data.sh")
# }

