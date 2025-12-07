provider "aws" {
  region = "ap-south-1"
}

data "aws_vpc" "bala_vpc" {
  id = "vpc-0201cd6468d9031b2"
}

data "aws_subnet" "public1" {
  id = "subnet-0a5a591e69cc448cf"
}

data "aws_subnet" "public2" {
  id = "subnet-0002ec646189d4d6f"
}

data "aws_subnet" "private1" {
  id = "subnet-04049757a18e73ef5"
}

data "aws_subnet" "private2" {
  id = "subnet-099ed94e64037db29"
}

resource "aws_security_group" "bala_private_sg" {
  name   = "bala-private-sg"
  vpc_id = data.aws_vpc.bala_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.bala_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bala-Private-SG"
  }
}

resource "aws_security_group" "bala_alb_sg" {
  name   = "bala-alb-sg"
  vpc_id = data.aws_vpc.bala_vpc.id

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
    Name = "Bala-ALB-SG"
  }
}

resource "aws_launch_template" "bala_lt" {
  name_prefix   = "bala-lt-"
  image_id      = "ami-0a0f1259dd1c90938"
  instance_type = "t2.micro"
  user_data     = filebase64("user_data.sh")

  vpc_security_group_ids = [aws_security_group.bala_private_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Bala-ASG-Instance"
    }
  }
}

resource "aws_lb_target_group" "bala_tg" {
  name        = "bala-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.bala_vpc.id
  target_type = "instance"

  health_check {
    path                = "/"
    port                = "traffic-port"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb" "bala_alb" {
  name               = "bala-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.bala_alb_sg.id]
  subnets = [
    data.aws_subnet.public1.id,
    data.aws_subnet.public2.id
  ]
}

resource "aws_lb_listener" "bala_listener" {
  load_balancer_arn = aws_lb.bala_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.bala_tg.arn
  }
}

resource "aws_autoscaling_group" "bala_asg" {
  name                = "bala-asg"
  max_size            = 3
  min_size            = 1
  desired_capacity    = 2
  vpc_zone_identifier = [
    data.aws_subnet.private1.id,
    data.aws_subnet.private2.id
  ]

  launch_template {
    id      = aws_launch_template.bala_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.bala_tg.arn]
  health_check_type = "EC2"

  tag {
    key                 = "Name"
    value               = "Bala-ASG-Instance"
    propagate_at_launch = true
  }
}
