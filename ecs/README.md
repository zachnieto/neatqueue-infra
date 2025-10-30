# NeatQueue ECS Stack

This Terraform module creates:
- VPC with public/private subnets and NAT
- Security group for ECS tasks
- ECS cluster and CloudWatch log group
- IAM task execution and task roles
- Three base Fargate task definitions (tiers 1-3)
- S3 bucket + CloudFront CDN for public image storage and serving

Inputs:
- No image inputs are required; task definitions are pinned to the `main` tag in ECR.

After terraform apply, set these environment variables for the app server:
- `ECS_CLUSTER` = output `cluster`
- `ECS_SUBNETS` = comma-join of output `subnets_public` (use `subnets_private` if behind a load balancer)
- `ECS_SECURITY_GROUPS` = output `security_group_tasks`
- `ECS_TASK_TIER1` = output `task_defs.tier1`
- `IMAGES_BUCKET` = output `images_bucket_name` (for uploading images to S3)
- `CDN_URL` = output `cdn_url` (for serving images publicly)
- Optional: `ECS_ASSIGN_PUBLIC_IP` (set to ENABLED for public subnet tasks), `ECS_CONTAINER_NAME`, `ECS_SERVICE_PREFIX`

For detailed information about the CDN setup, see [CDN_README.md](CDN_README.md).


