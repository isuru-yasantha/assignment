/* Creating AWS ALB */

resource "aws_alb" "application_load_balancer" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets_id
  security_groups    = ["${var.alb_sg_id}"]
}

/* Creating AWS ALB TG */

resource "aws_lb_target_group" "target_group" {
  name        = "${var.project}-${var.environment}-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  
  health_check {
    healthy_threshold   = "2"
    interval            = "10"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/healthcheck"
    unhealthy_threshold = "2"
  }
  tags = {
    Application = var.project
    Environment = var.environment
  }
}

/* Creating HTTP listner */

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.id
  port              = "80"
  protocol          = "HTTP"

   default_action {
     type             = "forward"
     target_group_arn = aws_lb_target_group.target_group.id
   }
}