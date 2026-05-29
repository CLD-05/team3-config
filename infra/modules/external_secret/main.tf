resource "kubernetes_manifest" "external_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = var.external_secret_name
      namespace = var.namespace
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = var.secret_store_name
        kind = "SecretStore"
      }
      target = {
        name = var.target_k8s_secret_name
      }
      data = [
        {
          secretKey = var.k8s_secret_key
          remoteRef = {
            key      = var.aws_secretsmanager_key
            property = var.aws_secret_property
          }
        }
      ]
    }
  }
}
