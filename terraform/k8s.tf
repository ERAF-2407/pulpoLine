data "aws_ecr_authorization_token" "token" {}

resource "kubernetes_secret" "ecr_registry_secret" {
  metadata {
    name = "ecr-registry-secret"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${data.aws_ecr_authorization_token.token.proxy_endpoint}" = {
          auth = base64encode("AWS:${data.aws_ecr_authorization_token.token.password}")
        }
      }
    })
  }

  lifecycle {
    ignore_changes = [data]
  }
}

resource "kubernetes_service_account_v1" "ecr_updater_sa" {
  metadata {
    name      = "ecr-updater-sa"
    namespace = "default"
  }
}

resource "kubernetes_role_v1" "ecr_updater_role" {
  metadata {
    name      = "ecr-updater-role"
    namespace = "default"
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "create", "patch", "update", "delete"]
  }
}

resource "kubernetes_role_binding_v1" "ecr_updater_binding" {
  metadata {
    name      = "ecr-updater-binding"
    namespace = "default"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.ecr_updater_role.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.ecr_updater_sa.metadata[0].name
    namespace = "default"
  }
}

resource "kubernetes_cron_job_v1" "ecr_registry_updater" {
  metadata {
    name      = "ecr-registry-updater"
    namespace = "default"
  }
  spec {
    schedule                      = "0 */6 * * *"
    successful_jobs_history_limit = 1
    failed_jobs_history_limit     = 1
    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            service_account_name = kubernetes_service_account_v1.ecr_updater_sa.metadata[0].name
            container {
              name              = "ecr-updater"
              image             = "alpine:latest"
              image_pull_policy = "IfNotPresent"

              env {
                name = "AWS_ACCESS_KEY_ID"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.aws_credentials.metadata[0].name
                    key  = "AWS_ACCESS_KEY_ID"
                  }
                }
              }
              env {
                name = "AWS_SECRET_ACCESS_KEY"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.aws_credentials.metadata[0].name
                    key  = "AWS_SECRET_ACCESS_KEY"
                  }
                }
              }
              env {
                name = "AWS_REGION"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.aws_credentials.metadata[0].name
                    key  = "AWS_REGION"
                  }
                }
              }
              env {
                name = "AWS_ACCOUNT_ID"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.aws_credentials.metadata[0].name
                    key  = "AWS_ACCOUNT_ID"
                  }
                }
              }

              command = ["/bin/sh", "-c"]
              args = [
                <<-EOF
                apk add --no-cache aws-cli kubectl
                echo "Obteniendo nuevo token de ECR..."
                TOKEN=$(aws ecr get-login-password --region $AWS_REGION)
                
                echo "Actualizando el secreto en Kubernetes..."
                kubectl delete secret ecr-registry-secret --ignore-not-found
                kubectl create secret docker-registry ecr-registry-secret \
                  --docker-server=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com \
                  --docker-username=AWS \
                  --docker-password="$TOKEN"
                
                echo "Secret actualizado correctamente."
                EOF
              ]
            }
            restart_policy = "Never"
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "api_deployment" {
  metadata {
    name = "api-backend-deployment"
    labels = {
      app         = "api-backend"
      environment = "staging"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "api-backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "api-backend"
        }
      }

      spec {
        image_pull_secrets {
          name = kubernetes_secret.ecr_registry_secret.metadata[0].name
        }

        container {
          name  = "api-container"
          image = "${aws_ecr_repository.api_backend_prod.repository_url}:latest"

          port {
            container_port = 8000
          }

          env {
            name  = "ENVIRONMENT"
            value = "staging"
          }

          resources {
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "api_service" {
  metadata {
    name = "api-backend-service"
  }
  spec {
    selector = {
      app = "api-backend"
    }
    port {
      port        = 80
      target_port = 8000
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "api_ingress" {
  metadata {
    name      = "api-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.api_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
