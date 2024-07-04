
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