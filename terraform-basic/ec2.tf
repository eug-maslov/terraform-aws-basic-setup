# ~/terraform/roadmap/proj1/ec2.tf

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
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet_a.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = var.ssh_key_name

  associate_public_ip_address = true
  
  iam_instance_profile = aws_iam_instance_profile.codedeploy_profile.name

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
    ManagedBy   = "Terraform"
    CodeDeploy  = "true"
  }
}

data "cloudinit_config" "user_data_config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "install.sh"
    content_type = "text/x-shellscript"
    content = <<-EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y ruby wget -y
wget https://aws-codedeploy-eu-north-1.s3.eu-north-1.amazonaws.com/latest/install -O /tmp/install

chmod +x /tmp/install

# Run the CodeDeploy agent installer. The 'auto' flag handles installation,
sudo /tmp/install auto

sudo systemctl start codedeploy-agent
sudo systemctl enable codedeploy-agent

sudo amazon-linux-extras install nginx1 -y
sudo systemctl start nginx
sudo systemctl enable nginx
    EOF
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