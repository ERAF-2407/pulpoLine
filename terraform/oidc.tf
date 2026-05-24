resource "aws_iam_openid_connect_provider" "gitlab" {
  url             = "https://gitlab.com"
  client_id_list  = ["https://gitlab.com"]
  thumbprint_list = ["3c4a8b66430edde6b6f03fd431e01a5e30fce540", "b3dd7606d2b5a8b4a13771dbecc9ee1cecafa38a"]
}

resource "aws_iam_role" "gitlab_actions_role" {
  name = "gitlab-ci-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.gitlab.arn
      }
      Condition = {
        StringLike = {
          "gitlab.com:sub" : "project_path:ERAF-2407/pulpoline:*"
        },
        StringEquals = {
          "gitlab.com:aud" : "https://gitlab.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "gitlab_actions_ecr_policy" {
  role       = aws_iam_role.gitlab_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy" "gitlab_actions_ecs_policy" {
  name = "gitlab-ci-ecs-deploy-policy"
  role = aws_iam_role.gitlab_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "iam:PassRole"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
