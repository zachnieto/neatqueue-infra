variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-2"
}

variable "project" {
  type        = string
  description = "Project name prefix"
  default     = "neatqueue"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.20.101.0/24", "10.20.102.0/24"]
}

// image tag now pinned to main in task definitions

variable "execution_role_policy_arns" {
  type        = list(string)
  default     = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

variable "task_role_policy_arns" {
  type        = list(string)
  default     = []
}

variable "github_owner" {
  type        = string
  description = "GitHub organization/user that owns the repository"
  default     = "zachnieto"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
  default = "neatqueue"
}

variable "allowed_branches" {
  type        = list(string)
  default     = ["dev", "main"]
}


