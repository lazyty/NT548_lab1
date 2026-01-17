# Output values

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.vpc.private_subnet_id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.vpc.nat_gateway_id
}

output "public_ec2_ip" {
  description = "Public IP of the public EC2 instance"
  value       = module.ec2.public_ec2_ip
}

output "private_ec2_ip" {
  description = "Private IP of the private EC2 instance"
  value       = module.ec2.private_ec2_ip
}

output "public_security_group_id" {
  description = "ID of the public security group"
  value       = module.security_groups.public_sg_id
}

output "private_security_group_id" {
  description = "ID of the private security group"
  value       = module.security_groups.private_sg_id
}