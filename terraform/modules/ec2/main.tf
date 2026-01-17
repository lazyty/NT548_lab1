# EC2 Module

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
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
}

# Public EC2 Instance
resource "aws_instance" "public" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.public_security_group_id]

  # User data script for initial setup
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>NT548 Public EC2 Instance</h1>" > /var/www/html/index.html
              echo "<p>This is the public EC2 instance in the public subnet.</p>" >> /var/www/html/index.html
              echo "<p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" >> /var/www/html/index.html
              EOF
  )

  tags = merge(var.tags, {
    Name = "NT548-Public-EC2"
    Type = "Public"
  })
}

# Private EC2 Instance
resource "aws_instance" "private" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.private_security_group_id]

  # User data script for initial setup
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>NT548 Private EC2 Instance</h1>" > /var/www/html/index.html
              echo "<p>This is the private EC2 instance in the private subnet.</p>" >> /var/www/html/index.html
              echo "<p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" >> /var/www/html/index.html
              echo "<p>This instance can only be accessed from the public instance.</p>" >> /var/www/html/index.html
              EOF
  )

  tags = merge(var.tags, {
    Name = "NT548-Private-EC2"
    Type = "Private"
  })
}