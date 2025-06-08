# ~/terraform/roadmap/proj1/variables.tf

variable "project_name" {
  description = "The name of the project. Used for naming resources."
  type        = string
  default     = "my-app"
}

variable "environment" {
  description = "The deployment environment (e.g., development, staging, production)."
  type        = string
  default     = "development"
}

variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
  default     = "eu-north-1"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  description = "A list of CIDR blocks for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for EC2 instances."
  type        = string
  default     = "main server2" 
}

variable "ssh_ingress_cidr_blocks" {
  description = "A list of CIDR blocks from which SSH access (port 22) is allowed."
  type        = list(string)
  default     = ["45.89.90.136/32"] 
}
