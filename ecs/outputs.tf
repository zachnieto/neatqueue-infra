output "cluster" {
  value = aws_ecs_cluster.this.name
}

output "subnets_public" {
  value       = [for s in aws_subnet.public : s.id]
  description = "Use these subnets for ECS tasks that need direct public internet access"
}

output "subnets_private" {
  value       = [for s in aws_subnet.private : s.id]
  description = "Use these subnets for ECS tasks behind a load balancer or without public access"
}

output "security_group_tasks" {
  value = aws_security_group.ecs_tasks.id
}

output "task_defs" {
  value = {
    tier1 = aws_ecs_task_definition.tier1.arn
  }
}

output "cdn_domain_name" {
  value       = aws_cloudfront_distribution.images.domain_name
  description = "CloudFront distribution domain name for serving images"
}

output "cdn_url" {
  value       = "https://${aws_cloudfront_distribution.images.domain_name}"
  description = "Full HTTPS URL for the CloudFront CDN"
}

output "cdn_distribution_id" {
  value       = aws_cloudfront_distribution.images.id
  description = "CloudFront distribution ID (useful for cache invalidation)"
}

output "images_bucket_name" {
  value       = aws_s3_bucket.images.id
  description = "S3 bucket name for image storage"
}

output "images_bucket_arn" {
  value       = aws_s3_bucket.images.arn
  description = "S3 bucket ARN for image storage"
}


