# ~/terraform/roadmap/proj1/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

    backend "s3" {
    bucket      = "my-app-terraform-state-zentawrus" 
    key         = "my-app/state/terraform.tfstate"  
    region      = "eu-north-1"
    encrypt     = true                                   
    use_lockfile = true                                  
   profile     = "terraform"
  }

}

provider "aws" {
  region  = "eu-north-1"
  profile = "terraform" 
}

data "aws_prefix_list" "s3"            { name = "com.amazonaws.${var.aws_region}.s3" }
data "aws_prefix_list" "ssm"           { name = "com.amazonaws.${var.aws_region}.ssm" }
data "aws_prefix_list" "ssmmessages"   { name = "com.amazonaws.${var.aws_region}.ssmmessages" }
data "aws_prefix_list" "ec2messages"   { name = "com.amazonaws.${var.aws_region}.ec2messages" }
data "aws_prefix_list" "logs"          { name = "com.amazonaws.${var.aws_region}.logs" }


resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway_attachment" "main_igw_attachment" {
  vpc_id              = aws_vpc.main.id
  internet_gateway_id = aws_internet_gateway.main_igw.id
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_blocks[0]
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-a"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_blocks[1]
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-b"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

resource "aws_route_table_association" "public_a_rt_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b_rt_association" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Allow SSH, HTTP, and HTTPS inbound traffic to web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ingress_cidr_blocks
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
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    prefix_list_ids   = [
      data.aws_prefix_list.s3.id,
      data.aws_prefix_list.ssm.id,
      data.aws_prefix_list.ssmmessages.id,
      data.aws_prefix_list.ec2messages.id,
      data.aws_prefix_list.logs.id
    ]
  }




  tags = {
    Name        = "${var.project_name}-web-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}