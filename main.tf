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
# creating subnet
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.dylo-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "production-subnet"
  }
}

# resource "aws_instance" "my-first-server" {
#   ami           = "ami-0e86e20dae9224db8"
#   instance_type = "t3.micro"
#   tags = {
#     Name = "MyTerraformInstance"

#   }
# }