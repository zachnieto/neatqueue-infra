resource "aws_ecr_repository" "neatqueue" {
  name                 = var.project
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name = var.project
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.neatqueue.repository_url
}


