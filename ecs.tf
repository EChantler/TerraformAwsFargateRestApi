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
      image     = var.container_image_url
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



