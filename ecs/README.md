# NeatQueue ECS Stack

This Terraform module creates:
- VPC with public/private subnets and NAT
- Security group for ECS tasks
- ECS cluster and CloudWatch log group
- IAM task execution and task roles
- Three base Fargate task definitions (tiers 1-3)

Inputs:
- No image inputs are required; task definitions are pinned to the `main` tag in ECR.

After terraform apply, set these environment variables for the app server:
- `ECS_CLUSTER` = output `cluster`
- `ECS_SUBNETS` = comma-join of output `subnets_private`
- `ECS_SECURITY_GROUPS` = output `security_group_tasks`
- `ECS_TASK_TIER1` = output `task_defs.tier1`
- `ECS_TASK_TIER2` = output `task_defs.tier2`
- `ECS_TASK_TIER3` = output `task_defs.tier3`
- Optional: `ECS_ASSIGN_PUBLIC_IP` (ENABLED|DISABLED), `ECS_CONTAINER_NAME`, `ECS_SERVICE_PREFIX`


