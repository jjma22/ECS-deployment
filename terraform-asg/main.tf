module "create-network" {
    source = "./module/network"
}

module "create-database" {
    source = "./module/database"
    db_subnet_group_name = module.create-network.private-subnet-group-name
    vpc_id = module.create-network.vpc_id
}

module "launch-instnace" {
    source = "./module/launch-instance"
    user-data = local.user_data_base64
    vpc_id = module.create-network.vpc_id
    ec2-subnet = module.create-network.public-subnet-group-name
    public_subnets = module.create-network.public-subnet-group-name
}

locals {
  user_data_file = file("${path.module}/user-data.sh")
  user_data_base64 = base64encode(local.user_data_file)
  
}