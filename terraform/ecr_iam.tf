resource "aws_iam_user" "ecr_updater" {
  name = "k8s-ecr-updater"
}

resource "aws_iam_user_policy_attachment" "ecr_updater_policy" {
  user       = aws_iam_user.ecr_updater.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_access_key" "ecr_updater_keys" {
  user = aws_iam_user.ecr_updater.name
}

resource "kubernetes_secret" "aws_credentials" {
  metadata {
    name = "aws-ecr-credentials"
  }

  data = {
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.ecr_updater_keys.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.ecr_updater_keys.secret
    AWS_ACCOUNT_ID        = data.aws_caller_identity.current.account_id
    AWS_REGION            = "us-east-1"
  }
}

data "aws_caller_identity" "current" {}
