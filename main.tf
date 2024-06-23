terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}
provider "aws" {
  region = "eu-west-1"
}

// VPC

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "VPC"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"

  tags = {
    Name = "Subnet1"
  }
}


resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1b"

  tags = {
    Name = "Subnet2"
  }
}


resource "aws_internet_gateway" "IG" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Internet-Gateway"
  }
}


resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IG.id
  }
}


resource "aws_route_table_association" "RTA1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.RT.id
}


resource "aws_route_table_association" "RTA2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.RT.id
}


// Security groups
resource "aws_security_group" "InboundAlbSg" {
  name        = "InboundAlbSg"
  description = "Allow Port 80"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "InboundAlbSg"
  }
}
resource "aws_security_group" "AlbToEcsSg" {
  name        = "AlbToEcsSg"
  description = "Allow All TCP to Ecs"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [aws_security_group.InboundAlbSg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "AlbToEcsSg"
  }
}
resource "aws_security_group" "EcsToRdsSg" {
  name        = "EcsToRdsSg"
  description = "Allow mysql traffic from ecs"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.AlbToEcsSg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EcsToRdsSg"
  }
}
// RDS
resource "aws_db_subnet_group" "RdsSubnetGroup" {
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "RdsSubnetGroup"
  }
}
resource "aws_db_instance" "default" {
  allocated_storage    = 10
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  db_name                 = "mydb"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.EcsToRdsSg.id]
  db_subnet_group_name = aws_db_subnet_group.RdsSubnetGroup.name
}

// ALB
resource "aws_lb" "ApplicationLoadBalancer" {
  name               = "ApplicationLoadBalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.InboundAlbSg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "ApplicationLoadBalancer"
  }
}
resource "aws_lb_target_group" "TargetGroup" {
  name        = "TargetGroup"
  port        = "80"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "TargetGroup" 
  }
}
resource "aws_alb_listener" "Listener" {
  load_balancer_arn = aws_lb.ApplicationLoadBalancer.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.TargetGroup.id
    type             = "forward"
  }
}


// ECS
resource "aws_ecs_cluster" "EcsCluster" {
  name = "EcsCluster"

  tags = {
    Name = "EcsCluster"
  }
} 

resource "aws_ecs_task_definition" "TaskDefinition" {
  family                   = "TaskDefinition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode([
    {
      name      = "restfastapi"
      image     = "public.ecr.aws/j4x1k7z4/restfastapi:latest"
      cpu       = 0
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ECSService" {
  name                               = "ECSService"
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  cluster                            = aws_ecs_cluster.EcsCluster.id
  task_definition                    = aws_ecs_task_definition.TaskDefinition.arn
  scheduling_strategy                = "REPLICA"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  load_balancer {
    target_group_arn = aws_lb_target_group.TargetGroup.arn
    container_name   = "restfastapi"
    container_port   = 80
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.AlbToEcsSg.id]
    subnets          = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  }
}

// ECS Autoscaling policies

resource "aws_appautoscaling_target" "ecs_service_target" {
  max_capacity       = 10 
  min_capacity       = 1 
  resource_id        = "service/${aws_ecs_cluster.EcsCluster.name}/${aws_ecs_service.ECSService.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_target_tracking_policy" {
  name               = "ecs-target-tracking"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs_service_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value       = 67.5  
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300 
    scale_out_cooldown = 300 
  }
}
