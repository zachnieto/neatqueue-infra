resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "gha_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        for b in var.allowed_branches : "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${b}"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.gha_assume_role.json
}

# Broad ECR permissions for publishing images. Narrow if desired.
resource "aws_iam_role_policy_attachment" "gha_ecr_power_user" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Minimal ECS permissions to list services in the target cluster and force deployments
data "aws_iam_policy_document" "gha_ecs_deploy" {
  statement {
    actions = [
      "ecs:ListServices",
      "ecs:UpdateService"
    ]
    resources = [
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/neatqueue-cluster/*"
    ]
  }
}

resource "aws_iam_policy" "gha_ecs_deploy" {
  name   = "${var.project}-gha-ecs-deploy"
  policy = data.aws_iam_policy_document.gha_ecs_deploy.json
}

resource "aws_iam_role_policy_attachment" "gha_ecs_deploy_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.gha_ecs_deploy.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}


