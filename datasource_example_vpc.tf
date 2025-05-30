data "aws_vpc" "my_existing_vpc" {
  tags = {
    ManagedBy   = "Terraform"
    Name        = "my-app-vpc"
    Environment = "development"
  }
}

output "found_vpc_id" {
  description = "The ID of the VPC found by the data source."
  value       = data.aws_vpc.my_existing_vpc.id
}

output "found_vpc_cidr_block" {
  description = "The CIDR block of the VPC found by the data source."
  value       = data.aws_vpc.my_existing_vpc.cidr_block
}

output "found_vpc_tags" {
  description = "The tags of the VPC found by the data source (to confirm)."
  value       = data.aws_vpc.my_existing_vpc.tags
}

output "found_vpc_name_tag" {
  description = "The 'Name' tag value of the found VPC."
  value       = data.aws_vpc.my_existing_vpc.tags.Name
}