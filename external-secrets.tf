##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

data "google_client_config" "current" {}

# External Secrets will rely on External Secrets Operator installed in the cluster.
# The access to AWS Secrets Manager is managed through the IAM role associated with the Kubernetes service account.
locals {
  external_secrets_json = flatten([
    for key, secret in local.secrets_map : [
      for ent, value in tomap(jsondecode(data.google_secret_manager_secret_version.secret[key].secret_data)) : {
        secretKey = "${lower(secret.filtered_key)}_${lower(ent)}"
        remoteRef = {
          key      = secret.secret_name
          property = ent
        }
      }
    ] if startswith(data.google_secret_manager_secret_version.secret[key].secret_data, "{")
  ])
  external_secrets_plain = flatten([
    for key, secret in local.secrets_map : [
      {
        secretKey = secret.filtered_key
        remoteRef = {
          key = secret.secret_name
        }
      }
    ] if !startswith(data.google_secret_manager_secret_version.secret[key].secret_data, "{")
  ])
  external_secrets_data = concat(local.external_secrets_json, local.external_secrets_plain)
}

resource "kubernetes_manifest" "external_secret_store" {
  count = local.external_secrets_enabled && local.external_secrets_create_store && length(local.secrets_path_filter) > 0 ? 1 : 0
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "SecretStore"
    metadata = {
      name      = "${var.release.name}-external-secret-store"
      namespace = var.create_namespace ? kubernetes_namespace.this[0].metadata.0.name : data.kubernetes_namespace.this[0].metadata.0.name
    }
    spec = {
      provider = {
        gcpsm = {
          projectID                    = data.google_project.current.id
          location                     = var.region
          secretVersionSelectionPolicy = "LatestOrFetch"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "external_secret" {
  count = local.external_secrets_enabled && length(local.secrets_path_filter) > 0 ? 1 : 0
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "${var.release.name}-external-secret"
      namespace = var.create_namespace ? kubernetes_namespace.this[0].metadata.0.name : data.kubernetes_namespace.this[0].metadata.0.name
    }
    spec = {
      refreshPolicy   = try(var.secrets.external_secrets.on_change, false) ? "OnChange" : "Periodic"
      refreshInterval = try(var.secrets.external_secrets.refresh_interval, "1h")
      secretStoreRef = {
        kind = "SecretStore"
        name = local.external_secrets_create_store ? kubernetes_manifest.external_secret_store[0].object.metadata.name : var.secrets.external_secrets.store_name
      }
      target = {
        name           = "${var.release.name}-external-secret"
        creationPolicy = "Owner"
        deletionPolicy = "Retain"
      }
      data = local.external_secrets_data
    }
  }
}