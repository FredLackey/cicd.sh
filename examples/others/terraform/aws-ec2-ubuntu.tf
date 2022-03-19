terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.54"
    }
  }
}

provider "aws" {
  region      = "us-west-1"
  access_key  = ">>> ACCESS KEY HERE <<<"
  secret_key  = ">>> SECRET KEY HERE <<<"
}

resource "aws_vpc" "web_zone" {
  cidr_block            = "10.10.0.0/16"
  enable_dns_hostnames  = true
  enable_dns_support    = true
  tags = {
    Name="web_zone_vpc"
  }
}

resource "aws_security_group" "web_zone_sg" {
  name        = "web_zone_sg"
  vpc_id      = aws_vpc.web_zone.id
 
  ingress {
    protocol         = "tcp"
    from_port        = 22
    to_port          = 22
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
  
  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
  
  ingress {
    protocol         = "tcp"
    from_port        = 442
    to_port          = 442
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  egress {
    protocol          = "-1"
    from_port         = 0
    to_port           = 0
    cidr_blocks       = ["0.0.0.0/0"]
    self             = false
  }
 
  tags = {
    "Name"  = "web_zone_sg"
  }
}

resource "aws_subnet" "web_zone_subnet" {
  vpc_id                  = aws_vpc.web_zone.id
  cidr_block              = "10.10.10.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-1b"
 
  tags = {
    "Name"  = "web_zone_subnet"
  }
}

resource "aws_internet_gateway" "web_zone_gw" {
  vpc_id = aws_vpc.web_zone.id
 
  tags = {
    "Name"  = "web_zone_gw"
  }
}

resource "aws_route_table" "web_zone_rt" {
  vpc_id = aws_vpc.web_zone.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web_zone_gw.id
  }
 
  tags = {
    "Name"  = "web_zone_gw"
  }
}

resource "aws_route_table_association" "web_zone_rt_asso" {
  subnet_id      = aws_subnet.web_zone_subnet.id
  route_table_id = aws_route_table.web_zone_rt.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web_zone_www" {
  ami                         = data.aws_ami.ubuntu.id
  availability_zone           = "us-west-1b"
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_zone_sg.id]
  subnet_id                   = aws_subnet.web_zone_subnet.id
  key_name                    = "terraform-test-keypair"

  user_data = <<-EOL
              #!/bin/bash
              sudo apt update
              sudo apt install -y apache2
              EOL

  tags = {
    Name = "web_zone_www"
  }
}

output "web_zone_www_ip" {
  value = aws_instance.web_zone_www.public_ip
}