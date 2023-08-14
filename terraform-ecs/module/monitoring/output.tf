output "ec2_ip" {
  value = module.ec2_instance.private_ip
}

output "monitoring_address" {
  value = module.ec2_instance.public_dns
}
