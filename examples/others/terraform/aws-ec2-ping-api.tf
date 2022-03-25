terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.54"
    }
  }
}

provider "aws" {
  region = "us-west-1"
  access_key = ">>> ACCESS KEY HERE <<<"
  secret_key = ">>> SECRET KEY HERE <<<"
}

resource "aws_vpc" "public_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "public_vpc"
  }
}

resource "aws_iam_role" "ping_task_execution_role" {
  name = "ping_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "ping_task_execution_role"
  }
}

resource "aws_iam_role_policy_attachment" "ping_task_execution_role_attach" {
  role       = aws_iam_role.ping_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_internet_gateway" "public_vpc_igw" {
  vpc_id = aws_vpc.public_vpc.id
  tags = {
    Name = "public_vpc_igw"
  }
}

resource "aws_route" "public_vpc_route" {
  route_table_id  = aws_vpc.public_vpc.main_route_table_id
  gateway_id      = aws_internet_gateway.public_vpc_igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_subnet" "public_vpc_subnet" {
  vpc_id      = aws_vpc.public_vpc.id
  cidr_block  = "10.0.0.0/20"
  tags = {
    Name = "public_vpc_subnet"
  }
}

resource "aws_security_group" "public_vpc_sg" {
  vpc_id      = aws_vpc.public_vpc.id

  name        = "public_vpc_sg"
  description = "public_vpc_sg"
  tags = {
    Name = "public_vpc_sg"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "out_all"
  }

  # ingress {
  #   protocol  = -1
  #   self      = true
  #   from_port = 0
  #   to_port   = 0
  #   description = "in_all"
  # }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    description = "in_https"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    description = "in_http"
  }

}

resource "aws_ecs_cluster" "ping_cluster" {
  name = "ping_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "ping_task" {
  family                        = "ping_task"
  network_mode                  = "awsvpc"
  requires_compatibilities      = ["FARGATE", "EC2"]
  cpu                           = 512
  memory                        = 2048
  execution_role_arn = aws_iam_role.ping_task_execution_role.arn

  container_definitions         = jsonencode([
    {
      name      = "complexapi"
      image     = "138563826014.dkr.ecr.us-west-1.amazonaws.com/complexapi:latest"
      cpu       = 512
      memory    = 2048
      essential = true  # if true and if fails, all other containers fail. Must have at least one essential
      environment = [
        {
          "name"  : "NODE_PORT", 
          "value" : "80"
        }
      ],
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ping_service" {
  name              = "ping_service"
  cluster           = aws_ecs_cluster.ping_cluster.id
  task_definition   = aws_ecs_task_definition.ping_task.id
  desired_count     = 1
  launch_type       = "FARGATE"
  platform_version  = "LATEST"

  network_configuration {
    assign_public_ip  = true
    security_groups   = [aws_security_group.public_vpc_sg.id]
    subnets           = [aws_subnet.public_vpc_subnet.id]
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}
