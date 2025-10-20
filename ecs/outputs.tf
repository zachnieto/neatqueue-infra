output "cluster" {
  value = aws_ecs_cluster.this.name
}

output "subnets_private" {
  value = [for s in aws_subnet.private : s.id]
}

output "security_group_tasks" {
  value = aws_security_group.ecs_tasks.id
}

output "task_defs" {
  value = {
    tier1 = aws_ecs_task_definition.tier1.arn
    tier2 = aws_ecs_task_definition.tier2.arn
    tier3 = aws_ecs_task_definition.tier3.arn
  }
}


