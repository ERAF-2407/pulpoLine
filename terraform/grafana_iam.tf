resource "aws_iam_user" "grafana" {
  name = "grafana-cloudwatch-reader"
}

resource "aws_iam_user_policy_attachment" "grafana_cloudwatch" {
  user       = aws_iam_user.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_access_key" "grafana_keys" {
  user = aws_iam_user.grafana.name
}

output "grafana_access_key_id" {
  value       = aws_iam_access_key.grafana_keys.id
  description = "Access Key para configurar en Grafana CloudWatch Data Source"
}

output "grafana_secret_access_key" {
  value       = aws_iam_access_key.grafana_keys.secret
  description = "Secret Key para configurar en Grafana CloudWatch Data Source"
  sensitive   = true
}
