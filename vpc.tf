# main.tf

provider "aws" {
  region  = "eu-north-1"  
  profile = "terraform"  
}

locals {
  vpc_cidr_block = "10.0.0.0/16"
  project_name   = "my-multi-subnet-vpc"
  environment    = "development"

  az_a = "eu-north-1a"
  az_b = "eu-north-1b"
}

resource "aws_vpc" "main" {
  cidr_block       = local.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name        = "${local.project_name}-vpc"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway" "main_igw" {
  tags = {
    Name        = "${local.project_name}-igw"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway_attachment" "main_igw_attachment" {
  vpc_id              = aws_vpc.main.id
  internet_gateway_id = aws_internet_gateway.main_igw.id
}

# Public Subnet 1 in eu-north-1a
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = local.az_a
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.project_name}-public-a"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

# Public Subnet 2 in eu-north-1b
resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = local.az_b
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.project_name}-public-b"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id 

  tags = {
    Name        = "${local.project_name}-public-rt"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}


resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"               
  gateway_id             = aws_internet_gateway.main_igw.id 
}


resource "aws_route_table_association" "public_a_rt_association" {
  subnet_id      = aws_subnet.public_subnet_a.id #
  route_table_id = aws_route_table.public_rt.id  
}


resource "aws_route_table_association" "public_b_rt_association" {
  subnet_id      = aws_subnet.public_subnet_b.id 
  route_table_id = aws_route_table.public_rt.id 
}


resource "aws_security_group" "web_sg" {
  name        = "${local.project_name}-web-sg" # A unique name for the security group
  description = "Allow SSH, HTTP, and HTTPS inbound traffic to web servers"
  vpc_id      = aws_vpc.main.id 


  ingress {
    description = "Allow SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["45.89.90.136/32"] 
  }

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0                 # All ports
    to_port     = 0                 # All ports
    protocol    = "-1"              # "-1" means all protocols
    cidr_blocks = ["0.0.0.0/0"]     # Allow outbound to anywhere (all IPv4 addresses)
  }

  tags = {
    Name        = "${local.project_name}-web-sg"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}


output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_arn" {
  value = aws_vpc.main.arn
}

output "vpc_cidr_block_used" {
  value = aws_vpc.main.cidr_block
}

output "vpc_name_tag" {
  value = aws_vpc.main.tags.Name
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main_igw.id
}

output "public_subnet_a_id" {
  value       = aws_subnet.public_subnet_a.id
  description = "ID of the first public subnet in AZ A."
}

output "public_subnet_b_id" {
  value       = aws_subnet.public_subnet_b.id
  description = "ID of the second public subnet in AZ B."
}

output "public_route_table_id" {
  value       = aws_route_table.public_rt.id
  description = "ID of the public route table."
}

output "web_security_group_id" {
  value       = aws_security_group.web_sg.id
  description = "ID of the web server security group."
}
