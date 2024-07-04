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
