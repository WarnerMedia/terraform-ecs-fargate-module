# create ci/cd user with access keys (for build system)
resource "aws_iam_user" "cicd" {
  count = var.create_cicd_user ? 1 : 0
  name  = "srv_${var.app}_${var.environment}_cicd"
  tags  = var.tags
}

resource "aws_iam_access_key" "cicd_keys" {
  count = var.create_cicd_user ? 1 : 0
  user  = aws_iam_user.cicd[0].name
}

# grant required permissions to deploy
data "aws_iam_policy_document" "cicd_policy" {
    count = var.create_cicd_user ? 1 : 0

  # allows user to push/pull to the registry
  statement {
    sid = "ecr"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]

    resources = [
      data.aws_ecr_repository.ecr[0].arn,
    ]
  }

  # allows user to deploy to ecs
  statement {
    sid = "ecs"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:UpdateService",
      "ecs:RegisterTaskDefinition",
    ]

    resources = [
      "*",
    ]
  }

  # allows user to run ecs task using task execution and app roles
  statement {
    sid = "approle"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      aws_iam_role.app_role.arn,
      aws_iam_role.ecsTaskExecutionRole.arn,
    ]
  }
}

resource "aws_iam_user_policy" "cicd_user_policy" {
  count  = var.create_cicd_user ? 1 : 0
  name   = "${var.app}_${var.environment}_cicd"
  user   = aws_iam_user.cicd[0].name
  policy = data.aws_iam_policy_document.cicd_policy[0].json
}

data "aws_ecr_repository" "ecr" {
  count = var.create_cicd_user ? 1 : 0
  name = var.default_ecr
}

# A command to run that can extract the AWS keys for the CICD user to use in a build system
#  (remove the \ in the select section
output "cicd_keys" {
  value = <<EOT
  >> Copy and paste this command to see the AWS IAM keys for CICD:
terraform show -json |
jq '.values.root_module.child_modules[].resources[] | select ( .address == "module.fargate.aws_iam_access_key.cicd_keys[0]") |.values| { AWS_ACCESS_KEY_ID: .id, AWS_SECRET_ACCESS_KEY: .secret }'
EOT
}
