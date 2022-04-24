terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10"
    }
  }
}

provider "aws" {
  region = "us-west-1"
  access_key = ">> ACCESS KEY HERE <<"
  secret_key = ">> SECRET KEY HERE <<"
}

#region Roles
resource "aws_iam_role" "example_task_execution_role" {
  name = "example_task_execution_role"
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
    Name = "example_task_execution_role"
  }
}
resource "aws_iam_role_policy_attachment" "example_task_execution_role_attach" {
  role       = aws_iam_role.example_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
#endregion

#region VPCs
resource "aws_vpc" "example_vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "example_vpc"
  }
}
#endregion

#region Logging
resource "aws_cloudwatch_log_group" "example_vpc_logs" {
  name = "example_vpc_logs"
  tags = {
    Name = "example_vpc_logs"
  }
}

resource "aws_cloudwatch_log_group" "ecs_landing_task" {
  name = "/ecs/landing_task"
  tags = {
    Name = "ecs_landing_task"
  }
}

resource "aws_cloudwatch_log_group" "ecs_adminuxapi_task" {
  name = "/ecs/adminuxapi_task"
  tags = {
    Name = "ecs_adminuxapi_task"
  }
}

resource "aws_cloudwatch_log_group" "ecs_studentuxapi_task" {
  name = "/ecs/studentuxapi_task"
  tags = {
    Name = "ecs_studentuxapi_task"
  }
}

resource "aws_cloudwatch_log_group" "ecs_mgmtapi_task" {
  name = "/ecs/mgmtapi_task"
  tags = {
    Name = "ecs_mgmtapi_task"
  }
}

resource "aws_cloudwatch_log_group" "ecs_mysqldb_task" {
  name = "/ecs/mysqldb_task"
  tags = {
    Name = "ecs_mysqldb_task"
  }
}
resource "aws_cloudwatch_log_group" "ecs_postgresdb_task" {
  name = "/ecs/postgresdb_task"
  tags = {
    Name = "ecs_postgresdb_task"
  }
}
resource "aws_cloudwatch_log_group" "ecs_redis_task" {
  name = "/ecs/redis_task"
  tags = {
    Name = "ecs_redis_task"
  }
}

#endregion

#region Subnets
resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.10.1.0/25"
  availability_zone = "us-west-1c"
  tags = {
    Name = "public_subnet_a"
  }
}
resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.10.1.128/25"
  availability_zone = "us-west-1b"
  tags = {
    Name = "public_subnet_b"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.10.2.0/25"
  availability_zone = "us-west-1c"
  tags = {
    Name = "private_subnet_a"
  }
}
resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.10.2.128/25"
  availability_zone = "us-west-1b"
  tags = {
    Name = "private_subnet_b"
  }
}

resource "aws_subnet" "secure_subnet_a" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.10.3.0/25"
  availability_zone = "us-west-1c"
  tags = {
    Name = "secure_subnet_a"
  }
}
resource "aws_subnet" "secure_subnet_b" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.10.3.128/25"
  availability_zone = "us-west-1b"
  tags = {
    Name = "secure_subnet_b"
  }
}
#endregion

#region Gateways
resource "aws_internet_gateway" "example_vpc_igw" {
  vpc_id = aws_vpc.example_vpc.id
  tags = {
    Name = "example_vpc_igw"
  }
}

resource "aws_eip" "ngw_eip_a" {
}
resource "aws_nat_gateway" "example_vpc_ngw_a" {
  subnet_id     = aws_subnet.public_subnet_a.id
  allocation_id = aws_eip.ngw_eip_a.id
  depends_on    = [aws_internet_gateway.example_vpc_igw]
}

resource "aws_eip" "ngw_eip_b" {
}
resource "aws_nat_gateway" "example_vpc_ngw_b" {
  subnet_id     = aws_subnet.public_subnet_b.id
  allocation_id = aws_eip.ngw_eip_b.id
  depends_on    = [aws_internet_gateway.example_vpc_igw]
}
#endregion

#region Routes
resource "aws_route" "example_vpc_route" {
  route_table_id         = aws_vpc.example_vpc.main_route_table_id
  gateway_id             = aws_internet_gateway.example_vpc_igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "private_route_a" {
  vpc_id = aws_vpc.example_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example_vpc_ngw_a.id
  }

  tags = {
    Name = "private_route_a"
  }

  depends_on = [
    aws_nat_gateway.example_vpc_ngw_a
  ]
}
resource "aws_route_table_association" "private_route_assoc_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_a.id
}

resource "aws_route_table" "private_route_b" {
  vpc_id = aws_vpc.example_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example_vpc_ngw_b.id
  }

  tags = {
    Name = "private_route_b"
  }

  depends_on = [
    aws_nat_gateway.example_vpc_ngw_b
  ]
}
resource "aws_route_table_association" "private_route_assoc_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_route_b.id
}

resource "aws_route_table" "secure_route_a" {
  vpc_id = aws_vpc.example_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example_vpc_ngw_a.id
  }

  tags = {
    Name = "secure_route_a"
  }

  depends_on = [
    aws_nat_gateway.example_vpc_ngw_a
  ]
}
resource "aws_route_table_association" "secure_route_assoc_a" {
  subnet_id      = aws_subnet.secure_subnet_a.id
  route_table_id = aws_route_table.secure_route_a.id
}
resource "aws_route_table" "secure_route_b" {
  vpc_id = aws_vpc.example_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example_vpc_ngw_b.id
  }

  tags = {
    Name = "secure_route_b"
  }

  depends_on = [
    aws_nat_gateway.example_vpc_ngw_b
  ]
}
resource "aws_route_table_association" "secure_route_assoc_b" {
  subnet_id      = aws_subnet.secure_subnet_b.id
  route_table_id = aws_route_table.secure_route_b.id
}
#endregion

#region Security Groups
resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.example_vpc.id

  name        = "public_sg"
  description = "public_sg"
  tags = {
    Name = "public_sg"
  }
}
resource "aws_security_group_rule" "public_sg_out_allow" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_sg.id
  description       = "out_all"
}
resource "aws_security_group_rule" "public_sg_in_allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_sg.id
  description       = "in_http"
}
resource "aws_security_group_rule" "public_sg_in_allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_sg.id
  description       = "in_http"
}

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.example_vpc.id

  name        = "private_sg"
  description = "private_sg"
  tags = {
    Name = "private_sg"
  }
}
resource "aws_security_group_rule" "private_sg_out_allow" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private_sg.id
  description       = "out_all"
}
resource "aws_security_group_rule" "private_sg_in_allow_http" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = [
    aws_subnet.public_subnet_a.cidr_block,
    aws_subnet.public_subnet_b.cidr_block,
  ]
  security_group_id = aws_security_group.private_sg.id
  description       = "in_http"
}
resource "aws_security_group_rule" "private_sg_in_allow_https" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = [
    aws_subnet.public_subnet_a.cidr_block,
    aws_subnet.public_subnet_b.cidr_block,
  ]
  security_group_id = aws_security_group.private_sg.id
  description       = "in_http"
}
resource "aws_security_group_rule" "private_sg_in_allow_healthcheck_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.private_sg.id
  description       = "in_http"
}
resource "aws_security_group_rule" "private_sg_in_allow_healthcheck_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.private_sg.id
  description       = "in_http"
}

resource "aws_security_group" "secure_sg" {
  vpc_id = aws_vpc.example_vpc.id

  name        = "secure_sg"
  description = "secure_sg"
  tags = {
    Name = "secure_sg"
  }
}
resource "aws_security_group_rule" "secure_sg_out_allow" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "out_all"
}
resource "aws_security_group_rule" "secure_sg_in_allow_http" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = [
    aws_subnet.private_subnet_a.cidr_block,
    aws_subnet.private_subnet_b.cidr_block,
  ]
  security_group_id = aws_security_group.secure_sg.id
  description       = "in_http"
}
resource "aws_security_group_rule" "secure_sg_in_allow_https" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = [
    aws_subnet.private_subnet_a.cidr_block,
    aws_subnet.private_subnet_b.cidr_block,
  ]
  security_group_id = aws_security_group.secure_sg.id
  description       = "in_http"
}
resource "aws_security_group_rule" "secure_sg_allow_in_healthcheck_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.secure_sg.id
  description       = "in_http"
}
resource "aws_security_group_rule" "secure_sg_allow_in_healthcheck_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.secure_sg.id
  description       = "in_http"
}
#endregion

#region Load Balancers
resource "aws_lb" "public_lb" {
  name               = "public-lb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.public_sg.id]
  subnets = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id
  ]
  enable_deletion_protection = false
  tags = {
    Name = "public-lb"
  }
}
resource "aws_alb_listener" "public_listener" {
  load_balancer_arn = aws_lb.public_lb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.landing_targets.id
    type             = "forward"
  }
}
resource "aws_alb_target_group" "adminuxapi_targets" {
  name        = "adminuxapi-targets"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.example_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = {
    Name = "adminuxapi-targets"
  }
}
resource "aws_alb_target_group" "studentuxapi_targets" {
  name        = "studentuxapi-targets"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.example_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = {
    Name = "studentuxapi-targets"
  }
}
resource "aws_alb_target_group" "landing_targets" {
  name        = "landing-targets"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.example_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = {
    Name = "landing-targets"
  }
}
resource "aws_alb_listener_rule" "adminuxapi_listener_rule" {
  listener_arn = aws_alb_listener.public_listener.arn
  priority     = 564

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.adminuxapi_targets.arn
  }

  condition {
    path_pattern {
      values = ["/adminuxapi*"]
    }
  }
}
resource "aws_alb_listener_rule" "studentuxapi_listener_rule" {
  listener_arn = aws_alb_listener.public_listener.arn
  priority     = 579

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.studentuxapi_targets.arn
  }

  condition {
    path_pattern {
      values = ["/studentuxapi*"]
    }
  }
}
resource "aws_alb_listener_rule" "landing_listener_rule" {
  listener_arn = aws_alb_listener.public_listener.arn
  priority     = 594

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.landing_targets.arn
  }

  condition {
    path_pattern {
      values = ["/landing*"]
    }
  }
}


resource "aws_lb" "private_lb" {
  name               = "private-lb"
  load_balancer_type = "application"
  internal           = true
  security_groups    = [aws_security_group.private_sg.id]
  subnets = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]
  enable_deletion_protection = false
  tags = {
    Name = "private-lb"
  }
}
resource "aws_alb_target_group" "mgmtapi_targets" {
  name        = "mgmtapi-targets"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.example_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = {
    Name = "mgmtapi-targets"
  }
}
resource "aws_alb_listener" "private_listener" {
  load_balancer_arn = aws_lb.private_lb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.mgmtapi_targets.id
    type             = "forward"
  }
}


resource "aws_lb" "secure_lb" {
  name               = "secure-lb"
  load_balancer_type = "application"
  internal           = true
  security_groups    = [aws_security_group.secure_sg.id]
  subnets = [
    aws_subnet.secure_subnet_a.id,
    aws_subnet.secure_subnet_b.id
  ]
  enable_deletion_protection = false
  tags = {
    Name = "secure_lb"
  }
}
resource "aws_alb_listener" "secure_listener" {
  load_balancer_arn = aws_lb.secure_lb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.redis_targets.id
    type             = "forward"
  }
}
resource "aws_alb_target_group" "redis_targets" {
  name        = "redis-targets"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.example_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = {
    Name = "redis-targets"
  }
}
resource "aws_alb_target_group" "mysqldb_targets" {
  name        = "mysqldb-targets"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.example_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = {
    Name = "mysqldb-targets"
  }
}
resource "aws_alb_target_group" "postgresdb_targets" {
  name        = "postgresdb-targets"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.example_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = {
    Name = "postgresdb-targets"
  }
}
resource "aws_alb_listener_rule" "redis_listener_rule" {
  listener_arn = aws_alb_listener.secure_listener.arn
  priority     = 745

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.redis_targets.arn
  }

  condition {
    path_pattern {
      values = ["/redis*"]
    }
  }
}
resource "aws_alb_listener_rule" "mysqldb_listener_rule" {
  listener_arn = aws_alb_listener.secure_listener.arn
  priority     = 760

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.mysqldb_targets.arn
  }

  condition {
    path_pattern {
      values = ["/mysqldb*"]
    }
  }
}
resource "aws_alb_listener_rule" "postgresdb_listener_rule" {
  listener_arn = aws_alb_listener.secure_listener.arn
  priority     = 775

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.postgresdb_targets.arn
  }

  condition {
    path_pattern {
      values = ["/postgresdb*"]
    }
  }
}
#endregion

#region Instances
resource "aws_ecs_cluster" "landing_cluster" {
  name = "landing_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
resource "aws_ecs_task_definition" "landing_task" {
  family                   = "landing_task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE", "EC2"]
  cpu                      = 512
  memory                   = 2048
  execution_role_arn       = aws_iam_role.example_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name        = "landing"
      image       = "nginxdemos/hello:latest"
      cpu         = 512
      memory      = 2048
      essential   = true 
      environment = [],
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/landing_task"
          awslogs-region        = "us-west-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
resource "aws_ecs_service" "landing_service" {
  name             = "landing_service"
  cluster          = aws_ecs_cluster.landing_cluster.id
  task_definition  = aws_ecs_task_definition.landing_task.id
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  load_balancer {
    target_group_arn = aws_alb_target_group.landing_targets.arn
    container_name   = "landing"
    container_port   = "80"
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.public_sg.id]
    subnets = [
      aws_subnet.public_subnet_a.id,
      aws_subnet.public_subnet_b.id
    ]
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}


resource "aws_ecs_cluster" "adminuxapi_cluster" {
  name = "adminuxapi_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
resource "aws_ecs_task_definition" "adminuxapi_task" {
  family                   = "adminuxapi_task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE", "EC2"]
  cpu                      = 512
  memory                   = 2048
  execution_role_arn       = aws_iam_role.example_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "adminuxapi"
      image     = "123456789012.dkr.ecr.us-west-1.amazonaws.com/complexapi:latest"
      cpu       = 512
      memory    = 2048
      essential = true 
      environment = [
        {
          "name" : "NODE_PORT",
          "value" : "80"
        },
        {
          "name" : "NODE_ALIAS",
          "value" : "ADMIN_UX_API"
        },
        {
          "name" : "NODE_BASE",
          "value" : "adminuxapi"
        },
        {
          "name" : "NODE_ENV",
          "value" : "development"
        },
        {
          "name" : "UPSTREAM_MGMTAPI",
          "value" : aws_lb.private_lb.dns_name
        }
      ],
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/adminuxapi_task"
          awslogs-region        = "us-west-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
resource "aws_ecs_service" "adminuxapi_service" {
  name             = "adminuxapi_service"
  cluster          = aws_ecs_cluster.adminuxapi_cluster.id
  task_definition  = aws_ecs_task_definition.adminuxapi_task.id
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  load_balancer {
    target_group_arn = aws_alb_target_group.adminuxapi_targets.arn
    container_name   = "adminuxapi"
    container_port   = "80"
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.public_sg.id]
    subnets = [
      aws_subnet.public_subnet_a.id,
      aws_subnet.public_subnet_b.id
    ]
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}


resource "aws_ecs_cluster" "studentuxapi_cluster" {
  name = "studentuxapi_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
resource "aws_ecs_task_definition" "studentuxapi_task" {
  family                   = "studentuxapi_task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE", "EC2"]
  cpu                      = 512
  memory                   = 2048
  execution_role_arn       = aws_iam_role.example_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "studentuxapi"
      image     = "123456789012.dkr.ecr.us-west-1.amazonaws.com/complexapi:latest"
      cpu       = 512
      memory    = 2048
      essential = true 
      environment = [
        {
          "name" : "NODE_PORT",
          "value" : "80"
        },
        {
          "name" : "NODE_ALIAS",
          "value" : "STUDENT_UX_API"
        },
        {
          "name" : "NODE_BASE",
          "value" : "studentuxapi"
        },
        {
          "name" : "NODE_ENV",
          "value" : "development"
        },
        {
          "name" : "UPSTREAM_MGMTAPI",
          "value" : aws_lb.private_lb.dns_name
        }
      ],
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/studentuxapi_task"
          awslogs-region        = "us-west-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
resource "aws_ecs_service" "studentuxapi_service" {
  name             = "studentuxapi_service"
  cluster          = aws_ecs_cluster.studentuxapi_cluster.id
  task_definition  = aws_ecs_task_definition.studentuxapi_task.id
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  load_balancer {
    target_group_arn = aws_alb_target_group.studentuxapi_targets.arn
    container_name   = "studentuxapi"
    container_port   = "80"
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.public_sg.id]
    subnets = [
      aws_subnet.public_subnet_a.id,
      aws_subnet.public_subnet_b.id
    ]
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}


resource "aws_ecs_cluster" "mgmtapi_cluster" {
  name = "mgmtapi_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
resource "aws_ecs_task_definition" "mgmtapi_task" {
  family                   = "mgmtapi_task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE", "EC2"]
  cpu                      = 512
  memory                   = 2048
  execution_role_arn       = aws_iam_role.example_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "mgmtapi"
      image     = "123456789012.dkr.ecr.us-west-1.amazonaws.com/complexapi:latest"
      cpu       = 512
      memory    = 2048
      essential = true 
      environment = [
        {
          "name" : "NODE_PORT",
          "value" : "80"
        },
        {
          "name" : "NODE_ALIAS",
          "value" : "MGMTAPI"
        },
        # {
        #   "name"  : "NODE_BASE", 
        #   "value" : "NOT NEEDED"
        # },    
        {
          "name" : "NODE_ENV",
          "value" : "development"
        },
        {
          "name" : "UPSTREAM_MYSQLDB",
          "value" : "${aws_lb.secure_lb.dns_name}/mysqldb"
        },
        {
          "name" : "UPSTREAM_POSTGRESDB",
          "value" : "${aws_lb.secure_lb.dns_name}/postgresdb"
        },
        {
          "name" : "UPSTREAM_REDIS",
          "value" : "${aws_lb.secure_lb.dns_name}/redis"
        }
      ],
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/mgmtapi_task"
          awslogs-region        = "us-west-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
resource "aws_ecs_service" "mgmtapi_service" {
  name             = "mgmtapi_service"
  cluster          = aws_ecs_cluster.mgmtapi_cluster.id
  task_definition  = aws_ecs_task_definition.mgmtapi_task.id
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  load_balancer {
    target_group_arn = aws_alb_target_group.mgmtapi_targets.arn
    container_name   = "mgmtapi"
    container_port   = "80"
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.private_sg.id]
    subnets = [
      aws_subnet.private_subnet_a.id,
      aws_subnet.private_subnet_b.id
    ]
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_ecs_cluster" "mysqldb_cluster" {
  name = "mysqldb_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
resource "aws_ecs_task_definition" "mysqldb_task" {
  family                   = "mysqldb_task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE", "EC2"]
  cpu                      = 512
  memory                   = 2048
  execution_role_arn       = aws_iam_role.example_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "mysqldb"
      image     = "123456789012.dkr.ecr.us-west-1.amazonaws.com/complexapi:latest"
      cpu       = 512
      memory    = 2048
      essential = true 
      environment = [
        {
          "name" : "NODE_PORT",
          "value" : "80"
        },
        {
          "name" : "NODE_ALIAS",
          "value" : "mysqldb"
        },
        {
          "name" : "NODE_BASE",
          "value" : "mysqldb"
        },
        {
          "name" : "NODE_ENV",
          "value" : "development"
        }
      ],
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/mysqldb_task"
          awslogs-region        = "us-west-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
resource "aws_ecs_service" "mysqldb_service" {
  name             = "mysqldb_service"
  cluster          = aws_ecs_cluster.mysqldb_cluster.id
  task_definition  = aws_ecs_task_definition.mysqldb_task.id
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  load_balancer {
    target_group_arn = aws_alb_target_group.mysqldb_targets.arn
    container_name   = "mysqldb"
    container_port   = "80"
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.secure_sg.id]
    subnets = [
      aws_subnet.secure_subnet_a.id,
      aws_subnet.secure_subnet_b.id,
    ]
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_ecs_cluster" "postgresdb_cluster" {
  name = "postgresdb_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
resource "aws_ecs_task_definition" "postgresdb_task" {
  family                   = "postgresdb_task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE", "EC2"]
  cpu                      = 512
  memory                   = 2048
  execution_role_arn       = aws_iam_role.example_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "postgresdb"
      image     = "123456789012.dkr.ecr.us-west-1.amazonaws.com/complexapi:latest"
      cpu       = 512
      memory    = 2048
      essential = true 
      environment = [
        {
          "name" : "NODE_PORT",
          "value" : "80"
        },
        {
          "name" : "NODE_ALIAS",
          "value" : "postgresdb"
        },
        {
          "name" : "NODE_BASE",
          "value" : "postgresdb"
        },
        {
          "name" : "NODE_ENV",
          "value" : "development"
        },
      ],
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/postgresdb_task"
          awslogs-region        = "us-west-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
resource "aws_ecs_service" "postgresdb_service" {
  name             = "postgresdb_service"
  cluster          = aws_ecs_cluster.postgresdb_cluster.id
  task_definition  = aws_ecs_task_definition.postgresdb_task.id
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  load_balancer {
    target_group_arn = aws_alb_target_group.postgresdb_targets.arn
    container_name   = "postgresdb"
    container_port   = "80"
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.secure_sg.id]
    subnets = [
      aws_subnet.secure_subnet_a.id,
      aws_subnet.secure_subnet_b.id,
    ]
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_ecs_cluster" "redis_cluster" {
  name = "redis_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
resource "aws_ecs_task_definition" "redis_task" {
  family                   = "redis_task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE", "EC2"]
  cpu                      = 512
  memory                   = 2048
  execution_role_arn       = aws_iam_role.example_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "redis"
      image     = "123456789012.dkr.ecr.us-west-1.amazonaws.com/complexapi:latest"
      cpu       = 512
      memory    = 2048
      essential = true 
      environment = [
        {
          "name" : "NODE_PORT",
          "value" : "80"
        },
        {
          "name" : "NODE_ALIAS",
          "value" : "redis"
        },
        {
          "name" : "NODE_BASE",
          "value" : "redis"
        },
        {
          "name" : "NODE_ENV",
          "value" : "development"
        },
      ],
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/redis_task"
          awslogs-region        = "us-west-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
resource "aws_ecs_service" "redis_service" {
  name             = "redis_service"
  cluster          = aws_ecs_cluster.redis_cluster.id
  task_definition  = aws_ecs_task_definition.redis_task.id
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  load_balancer {
    target_group_arn = aws_alb_target_group.redis_targets.arn
    container_name   = "redis"
    container_port   = "80"
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.secure_sg.id]
    subnets = [
      aws_subnet.secure_subnet_a.id,
      aws_subnet.secure_subnet_b.id,
    ]
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}

#endregion

output "public_url" {
  value = "http://${aws_lb.public_lb.dns_name}"
}
