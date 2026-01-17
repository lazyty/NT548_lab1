# EC2 Module Variables

variable "public_subnet_id" {
  description = "ID of the public subnet"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the private subnet"
  type        = string
}

variable "public_security_group_id" {
  description = "ID of the public security group"
  type        = string
}

variable "private_security_group_id" {
  description = "ID of the private security group"
  type        = string
}

variable "key_pair_name" {
  description = "Name of AWS key pair for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}