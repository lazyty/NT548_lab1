# EC2 Module Outputs

output "public_ec2_id" {
  description = "ID of the public EC2 instance"
  value       = aws_instance.public.id
}

output "private_ec2_id" {
  description = "ID of the private EC2 instance"
  value       = aws_instance.private.id
}

output "public_ec2_ip" {
  description = "Public IP of the public EC2 instance"
  value       = aws_instance.public.public_ip
}

output "private_ec2_ip" {
  description = "Private IP of the private EC2 instance"
  value       = aws_instance.private.private_ip
}

output "public_ec2_dns" {
  description = "Public DNS of the public EC2 instance"
  value       = aws_instance.public.public_dns
}