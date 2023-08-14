# output "address" {
#     value = "${module.launch-instnace.ec2-dns}:5000"
# }

output "public" {
    value = module.create-network.public-subnet-group-name
}