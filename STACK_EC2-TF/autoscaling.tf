####################LOAD-BALANCERS##########################
resource "aws_lb" "balance" {
  name                = "Stack-alb"
  internal            = false
  load_balancer_type  = "application"
  security_groups     = [aws_security_group.stack-sg.id]
  subnets             = [for s in data.aws_subnet.stack_sub : s.id]
}

resource "aws_lb" "blog_balance" {
  name                = "Blog-alb"
  internal            = false
  load_balancer_type  = "application"
  security_groups     = [aws_security_group.stack-sg.id]
  subnets             = [for s in data.aws_subnet.stack_sub : s.id]
}
   
resource "aws_lb_target_group" "balance_tg" {
  name            = "Stack-alb-tp"
  port            = 80
  protocol        = "HTTP"
  vpc_id          = var.default_vpc_id

  health_check {
    matcher             = "200,301,302"
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2

  } 
}

resource "aws_lb_target_group" "blog_tg" {
  name            = "Blog-alb-tp"
  port            = 80
  protocol        = "HTTP"
  vpc_id          = var.default_vpc_id

  health_check {
    matcher             = "200,301,302"
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2

  } 
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn     = aws_lb.balance.arn
  port                  = 80
  protocol              = "HTTP"
  default_action {
    type                = "forward"
    target_group_arn    = aws_lb_target_group.balance_tg.arn     
    } 
}     

resource "aws_lb_listener" "front_end_blog" {
  load_balancer_arn     = aws_lb.blog_balance.arn
  port                  = 80
  protocol              = "HTTP"
  default_action {
    type                = "forward"
    target_group_arn    = aws_lb_target_group.blog_tg.arn     
    } 
}

resource "aws_launch_template" "takeoff" {
  name          = var.project
  image_id      = data.aws_ami.stack_ami.id
  instance_type = var.instance_type
  user_data     = base64encode(data.template_file.bootstrapCliXX.rendered)

  vpc_security_group_ids = [aws_security_group.stack-sg.id]
  tags =  {

  }
}

resource "aws_launch_template" "blog_takeoff" {
  name          = "Blog-alt"
  image_id      = data.aws_ami.stack_ami.id
  instance_type = var.instance_type
  user_data     = base64encode(data.template_file.bootstrapBlog.rendered)

  vpc_security_group_ids = [aws_security_group.stack-sg.id]
  tags =  {

  }
}

resource "aws_autoscaling_group" "scale" {
  name                      = var.project
  max_size                  = 4
  min_size                  = 2
  desired_capacity          = 2
  health_check_grace_period = 30
  health_check_type         = "EC2"
  vpc_zone_identifier       = [
    "subnet-01126ecf89335cfb7",
    "subnet-015c0d22465c1a320",
    "subnet-043d6002b1c2fa406",
    "subnet-078613bbafffc2118" 
  ]

  metrics_granularity = "1Minute"

  launch_template {
    id      = aws_launch_template.takeoff.id
    version = aws_launch_template.takeoff.latest_version #"$Latest"
  }

  target_group_arns = [aws_lb_target_group.balance_tg.arn]
}

resource "aws_autoscaling_group" "blog_scale" {
  name                      = "Blog-ASP"
  max_size                  = 4
  min_size                  = 2
  desired_capacity          = 2
  health_check_grace_period = 30
  health_check_type         = "EC2"
  vpc_zone_identifier       = [
    "subnet-01126ecf89335cfb7",
    "subnet-015c0d22465c1a320",
    "subnet-043d6002b1c2fa406",
    "subnet-078613bbafffc2118" 
  ]

  metrics_granularity = "1Minute"

  launch_template {
    id      = aws_launch_template.blog_takeoff.id
    version = aws_launch_template.blog_takeoff.latest_version #"$Latest"
  }

  target_group_arns = [aws_lb_target_group.blog_tg.arn]
}

# scale up policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "CliXX-asp"
  autoscaling_group_name = aws_autoscaling_group.scale.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1" #increasing instance by 1 
  cooldown               = "30"
  policy_type            = "SimpleScaling"
}

# scale up policy
resource "aws_autoscaling_policy" "blog_scale_up" {
  name                   = "Blog-asp"
  autoscaling_group_name = aws_autoscaling_group.blog_scale.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1" #increasing instance by 1 
  cooldown               = "30"
  policy_type            = "SimpleScaling"
}

# scale down policy
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "CliXX-scale-down"
  autoscaling_group_name = aws_autoscaling_group.scale.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1" # decreasing instance by 1 
  cooldown               = "30"
  policy_type            = "SimpleScaling"
}

#scale down policy
resource "aws_autoscaling_policy" "blog_scale_down" {
  name                   = "Blog-scale-down"
  autoscaling_group_name = aws_autoscaling_group.blog_scale.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1" # decreasing instance by 1 
  cooldown               = "30"
  policy_type            = "SimpleScaling"
}