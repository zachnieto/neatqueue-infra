resource "aws_ecs_cluster" "this" {
  name = "${var.project}-cluster"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project}"
  retention_in_days = 14
}

locals {
  common_container = {
    name      = var.project
    essential = true
    image     = "${aws_ecr_repository.neatqueue.repository_url}:main"
    portMappings = [
      {
        containerPort = 2101
        hostPort      = 2101
        protocol      = "tcp"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.this.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = var.project
      }
    }
    environment = []
    secrets     = []
    healthCheck = {
      command     = ["CMD-SHELL", "curl -sf http://localhost:2101/healthcheck || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 10
    }
  }
}

resource "aws_ecs_task_definition" "tier1" {
  family                   = "${var.project}-t1"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    local.common_container
  ])
}

resource "aws_ecs_task_definition" "tier2" {
  family                   = "${var.project}-t2"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"  # Uses instance network stack (public IP)
  cpu                      = "1024"
  memory                   = "1536"  # Fits within 2GB t3.small (leaving ~500MB for OS)
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    local.common_container
  ])
}


# Data source to get latest ECS-optimized AMI
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# IAM role for EC2 instances
resource "aws_iam_role" "ecs_instance" {
  name = "${var.project}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name = "${var.project}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}

output "task_tier1_arn" {
  value = aws_ecs_task_definition.tier1.arn
}

output "task_tier2_arn" {
  value = aws_ecs_task_definition.tier2.arn
}

output "ecs_instance_profile_arn" {
  value = aws_iam_instance_profile.ecs_instance.arn
}

output "ecs_ami_id" {
  value     = data.aws_ssm_parameter.ecs_ami.value
  sensitive = true
}

# Launch template for EC2 instances that can run multiple tasks
resource "aws_launch_template" "ecs_instance" {
  name_prefix   = "${var.project}-ecs-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t3.small"  # One task per instance

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_instance.arn
  }

  vpc_security_group_ids = [aws_security_group.ecs_tasks.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
    echo ECS_ENABLE_TASK_ENI=true >> /etc/ecs/ecs.config
    echo ECS_AVAILABLE_LOGGING_DRIVERS='["json-file","awslogs"]' >> /etc/ecs/ecs.config
  EOF
  )

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-ecs-instance"
    }
  }
}

# Auto Scaling Group for ECS instances
resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project}-ecs-asg"
  vpc_zone_identifier = [for s in aws_subnet.public : s.id]
  min_size            = 1
  max_size            = 20
  desired_capacity    = 1
  protect_from_scale_in = true

  launch_template {
    id      = aws_launch_template.ecs_instance.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-ecs-instance"
    propagate_at_launch = true
  }
}

# ECS Capacity Provider for managed scaling
resource "aws_ecs_capacity_provider" "ec2" {
  name = "${var.project}-ec2-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100  # No spare capacity (1 task = 1 instance)
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 10
    }
  }
}

# Associate capacity provider with cluster
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = [aws_ecs_capacity_provider.ec2.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
    base              = 1
  }
}

output "launch_template_id" {
  value = aws_launch_template.ecs_instance.id
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.ec2.name
}


