terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket                  = "phillies-project"
    shared_config_files      = ["~/.aws/config"]
    shared_credentials_files = ["~/.aws/credentials"]
    region = "us-east-1"
    key = "terraform/terrafrom.tfstate"

  }
}

provider "aws" {
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
}

# Networking
resource "aws_vpc" "project-vpc" {
  cidr_block = var.cidr-vpc
  tags       = merge(var.tags)
}
resource "aws_security_group" "project-sg" {
  vpc_id     = aws_vpc.project-vpc.id
  tags       = merge(var.tags)
  depends_on = [aws_vpc.project-vpc]
}
resource "aws_security_group_rule" "project-ingress-80-sgr" {
  type              = "ingress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.project-sg.id
}
resource "aws_security_group_rule" "project-ingress-out-sgr" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.project-sg.id
}
resource "aws_subnet" "project-subnet-01" {
  vpc_id                  = aws_vpc.project-vpc.id
  cidr_block              = var.cidr-subnet-01
  availability_zone       = var.az-subnet-01
  map_public_ip_on_launch = var.pubip-subnet-01
  tags                    = merge(var.tags)
  depends_on              = [aws_vpc.project-vpc]
}
resource "aws_subnet" "project-subnet-02" {
  vpc_id                  = aws_vpc.project-vpc.id
  cidr_block              = var.cidr-subnet-02
  availability_zone       = var.az-subnet-02
  map_public_ip_on_launch = var.pubip-subnet-02
  tags                    = merge(var.tags)
  depends_on              = [aws_vpc.project-vpc]
}
# Internal gateway
resource "aws_internet_gateway" "project-igw" {
  vpc_id     = aws_vpc.project-vpc.id
  tags       = merge(var.tags)
  depends_on = [aws_vpc.project-vpc]
}
# Routes
resource "aws_route_table" "project-rt" {
  vpc_id     = aws_vpc.project-vpc.id
  tags       = merge(var.tags)
  route      = []
  depends_on = [aws_vpc.project-vpc]
}
resource "aws_route" "project-intv4-r" {
  route_table_id         = aws_route_table.project-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.project-igw.id
  depends_on             = [aws_internet_gateway.project-igw, aws_route_table.project-rt]
}
resource "aws_route" "project-intv6-r" {
  route_table_id              = aws_route_table.project-rt.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.project-igw.id
  depends_on                  = [aws_internet_gateway.project-igw, aws_route_table.project-rt]
}
resource "aws_route_table_association" "project-rt-subnet-01" {
  subnet_id      = aws_subnet.project-subnet-01.id
  route_table_id = aws_route_table.project-rt.id
  depends_on     = [aws_subnet.project-subnet-01, aws_route_table.project-rt]
}
resource "aws_route_table_association" "project-rt-subnet-02" {
  subnet_id      = aws_subnet.project-subnet-02.id
  route_table_id = aws_route_table.project-rt.id
  depends_on     = [aws_subnet.project-subnet-02, aws_route_table.project-rt]
}
#LB
resource "aws_lb" "project-lb" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.project-sg.id]
  subnets            = [aws_subnet.project-subnet-01.id, aws_subnet.project-subnet-02.id]
  tags               = merge(var.tags)
  depends_on         = [aws_security_group.project-sg, aws_subnet.project-subnet-01, aws_subnet.project-subnet-02]
}
resource "aws_lb_target_group" "project-80-lbtg" {
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.project-vpc.id
  tags        = merge(var.tags)
  depends_on  = [aws_vpc.project-vpc]
}
resource "aws_lb_listener" "project-80-lbl" {
  load_balancer_arn = aws_lb.project-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project-80-lbtg.arn
  }
  tags       = merge(var.tags)
  depends_on = [aws_lb.project-lb, aws_lb_target_group.project-80-lbtg]
}
# ECS
resource "aws_ecs_cluster" "project-cluster" {
  name = "project"
  tags = merge(var.tags)
}
resource "aws_ecs_cluster_capacity_providers" "project-clustercp" {
  cluster_name       = aws_ecs_cluster.project-cluster.name
  capacity_providers = ["FARGATE"]
  depends_on         = [aws_ecs_cluster.project-cluster]
}
resource "aws_ecs_task_definition" "project-nginx-svctd" {
  family                   = var.name-01
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = data.aws_iam_role.ecs_task_execution_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  network_mode = "awsvpc"
  cpu          = var.cpu-01
  memory       = var.memory-01
  container_definitions = templatefile(
    "${path.module}/templates/container-definition-01.json",
    {
      image         = var.image-01 == "" ? "null" : var.image-01
      name          = var.name-01 == "" ? "null" : var.name-01
      essential     = var.essential-01 ? true : false
      containerPort = var.containerPort-01 == 0 ? "null" : var.containerPort-01
      hostPort      = var.hostPort-01 == 0 ? "null" : var.hostPort-01
    }
  )
  tags = var.tags
}
resource "aws_ecs_service" "project-nginx-svc" {
  name                = var.name-01
  cluster             = aws_ecs_cluster.project-cluster.id
  task_definition     = aws_ecs_task_definition.project-nginx-svctd.arn
  desired_count       = var.desired-count-01
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"
  network_configuration {
    security_groups  = [aws_security_group.project-sg.id]
    subnets          = [aws_subnet.project-subnet-01.id, aws_subnet.project-subnet-02.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.project-80-lbtg.id
    container_name   = var.name-01
    container_port   = var.containerPort-01
  }
  depends_on = [aws_ecs_cluster.project-cluster, aws_ecs_task_definition.project-nginx-svctd, aws_security_group.project-sg, aws_subnet.project-subnet-01, aws_subnet.project-subnet-02, aws_lb_target_group.project-80-lbtg]
}