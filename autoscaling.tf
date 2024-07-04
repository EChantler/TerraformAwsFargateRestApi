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