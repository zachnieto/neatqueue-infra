data "aws_iam_policy_document" "task_execution_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "task_execution" {
  name               = "${var.project}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume.json
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  for_each = toset(var.execution_role_policy_arns)
  role     = aws_iam_role.task_execution.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "task_execution_secrets" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:neatqueue/*"
    ]
  }
}

resource "aws_iam_policy" "task_execution_secrets" {
  name   = "${var.project}-ecs-task-exec-secrets"
  policy = data.aws_iam_policy_document.task_execution_secrets.json
}

resource "aws_iam_role_policy_attachment" "task_execution_secrets" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.task_execution_secrets.arn
}

resource "aws_iam_role" "task_role" {
  name               = "${var.project}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume.json
}

resource "aws_iam_role_policy_attachment" "task_role" {
  for_each  = toset(var.task_role_policy_arns)
  role      = aws_iam_role.task_role.name
  policy_arn = each.value
}

# Policy for ECS tasks to access the images S3 bucket
data "aws_iam_policy_document" "task_s3_images" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.images.arn,
      "${aws_s3_bucket.images.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "task_s3_images" {
  name   = "${var.project}-ecs-task-s3-images"
  policy = data.aws_iam_policy_document.task_s3_images.json
}

resource "aws_iam_role_policy_attachment" "task_s3_images" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_s3_images.arn
}


