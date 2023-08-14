data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}


resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
}




resource "aws_security_group" "notes-sg-ecs" {
  name        = "notes-db-sg-ecs"
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
    from_port   = 1000
    to_port     = 1000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 9779
    to_port     = 9779
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["92.233.52.136/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_security_group_rule" "allow_notes_sg_ecs_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.notes-sg-ecs.id
  source_security_group_id = aws_security_group.notes-sg-ecs.id # Replace with the ID of the other security group
}

resource "aws_ecs_cluster" "cluster" {
  name = "ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_launch_template" "launch-template" {
  name     = "notes-lauch"
  image_id = "ami-060a7cb27aaa78d8d"
  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_agent.arn
  }
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.notes-sg-ecs.id]
  key_name               = "notes_keypair"
  user_data              = base64encode("#!/bin/bash\necho ECS_CLUSTER=ecs-cluster >> /etc/ecs/ecs.config")
  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 2
    }

  }
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = var.ec2-subnet
  desired_capacity    = 1
  max_size            = 1
  min_size            = 0

  launch_template {
    id      = aws_launch_template.launch-template.id
    version = "$Latest"
  }

}

resource "aws_lb_target_group" "tg" {
  name     = "notes-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "notes-alb"

  load_balancer_type = "application"

  vpc_id          = var.vpc_id
  subnets         = var.public_subnets
  security_groups = [aws_security_group.notes-sg-ecs.id]


}

resource "aws_alb_listener" "alb-listener-group" {
  load_balancer_arn = module.alb.lb_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.id
    type             = "forward"
  }
}

resource "aws_ecs_capacity_provider" "test" {
  name = "cluster-capacity"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.asg.arn
    managed_scaling {
      status                 = "ENABLED"
      instance_warmup_period = 300
      target_capacity        = 1
    }
  }

}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.cluster.name


  capacity_providers = [aws_ecs_capacity_provider.test.name]
}

resource "aws_ecs_task_definition" "service" {
  family = "flask-console"
  container_definitions = jsonencode([
    {
      name      = "flask-notes"
      image     = var.repository_url
      cpu       = 0
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 5000
          hostPort      = 0
        }
      ]
      logConfiguration : {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-create-group"  = "true",
          "awslogs-group"         = "/ecs/",
          "awslogs-region"        = "eu-west-2",
          "awslogs-stream-prefix" = "ecs"
        },
        "secretOptions" = []
      }
    },
    {
      name : "ecs-exporter"
      image : "quay.io/prometheuscommunity/ecs-exporter:latest"
      cpu : 0
      portMappings : [
        {
          name : "ecs-exporter-9779-tcp"
          containerPort : 9779
          hostPort : 9779
          protocol : "tcp"
          appProtocol : "http"
      }]
      essential : false
    }

  ])
  network_mode       = "bridge"
  execution_role_arn = "arn:aws:iam::253823465825:role/ecsTaskExecutionRole"
  cpu                = 256
  memory             = 512

}

resource "aws_ecs_service" "worker" {
  name            = "worker"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 1
  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "flask-notes"
    container_port   = 5000
  }

}

