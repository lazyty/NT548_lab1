# Security Groups Module Variables

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "allowed_ssh_ip" {
  description = "IP address allowed to SSH to public EC2"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}