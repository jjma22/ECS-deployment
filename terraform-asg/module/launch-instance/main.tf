

resource "aws_security_group" "notes-sg" {
  name        = "notes-db-sg-ec2"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


} 


resource "aws_launch_template" "notes-launch-template" {
  name = "notes-launch-template"
  image_id = "ami-0eb260c4d5475b901"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.notes-sg.id]
  key_name = "notes_keypair"
  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 2
    }
  }
  
  user_data = var.user-data
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = var.ec2-subnet
  desired_capacity   = 3
  max_size           = 3
  min_size           = 1

  launch_template {
    id      = aws_launch_template.notes-launch-template.id
    version = "$Latest"
  }

}

resource "aws_lb_target_group" "flask" {
  name     = "flask"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  lifecycle {
      create_before_destroy = true
    }
  
  health_check {
    path                = "/health"
    port                = 5000
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

}

resource "aws_autoscaling_attachment" "autoscale-attatch" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.flask.arn
}


module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "notes-alb"

  load_balancer_type = "application"

  vpc_id             = var.vpc_id
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.notes-sg.id]


}

resource "aws_alb_listener" "alb-listener-group" {
  load_balancer_arn = "${module.alb.lb_arn}"
  port = "5000"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.flask.id
    type             = "forward"
  }
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_description   = "Monitors CPU utilization for ASG"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  alarm_name          = "notes_scale_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "10"
  evaluation_periods  = "1"
  period              = "60"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_description   = "Monitors CPU utilization for ASG"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  alarm_name          = "notes_scale_up"
  comparison_operator = "GreaterThanThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "10"
  evaluation_periods  = "1"
  period              = "60"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}