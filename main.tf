terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}



#Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  
    
}

# Create a VPC
resource "aws_vpc" "dylo-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name="production"
  }
}
#create igw
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.dylo-vpc.id

}
#Create route table 
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.dylo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod"
  }
}
#creating subnet
resource "aws_subnet" "subnet-1" {
  vpc_id    =aws_vpc.dylo-vpc.id
  cidr_block ="10.0.1.0/24"
  availability_zone="us-east-1a"
  
  tags= {
    Name="production-subnet"
  }
}
#route table association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}
#create a security group
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow inbound web traffic and all outbound traffic"
  vpc_id      = aws_vpc.dylo-vpc.id

  tags = {
    Name = "allow_web_traffic"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4        = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4        = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#create a network interface
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}
#Assign an elastic ip
resource "aws_eip" "lb" {
  network_interface = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  domain   = "vpc"
  depends_on = [aws_internet_gateway.gw]
}
#create ubuntu server
resource "aws_instance" "web-server-instance" {
  ami = "ami-0e86e20dae9224db8"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id 
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c "echo 'your very first web server' > var/www/html/index.html"
              EOF
  tags = {
    Name= "web-server"
  }

}

# resource "aws_instance" "my-first-server" {
#   ami           = "ami-0e86e20dae9224db8"
#   instance_type = "t3.micro"
#   tags = {
#     Name = "MyTerraformInstance"

#   }
# }