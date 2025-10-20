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
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    local.common_container
  ])
}

resource "aws_ecs_task_definition" "tier2" {
  family                   = "${var.project}-t2"
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

resource "aws_ecs_task_definition" "tier3" {
  family                   = "${var.project}-t3"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    local.common_container
  ])
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

output "task_tier3_arn" {
  value = aws_ecs_task_definition.tier3.arn
}


