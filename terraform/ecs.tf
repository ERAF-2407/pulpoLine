resource "aws_cloudwatch_log_group" "ecs_cluster_logs" {
  name              = "/ecs/api-prod-cluster"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "api_prod_cluster" {
  name = "api-prod-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_cluster_logs.name
      }
    }
  }
}
