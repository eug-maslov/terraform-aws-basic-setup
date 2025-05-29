# ec2.tf

# Data source to find the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro"                    
  subnet_id                   = aws_subnet.public_subnet_a.id  
  vpc_security_group_ids      = [aws_security_group.web_sg.id] 
  key_name                    = "main server2"                  


  associate_public_ip_address = true

  tags = {
    Name        = "${local.project_name}-web-server"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}


output "web_server_instance_id" {
  value       = aws_instance.web_server.id
  description = "The ID of the created web server EC2 instance."
}

output "web_server_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "The public IP address of the web server EC2 instance."
}

output "web_server_private_ip" {
  value       = aws_instance.web_server.private_ip
  description = "The private IP address of the web server EC2 instance."
}
