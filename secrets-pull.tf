##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# data "aws_secretsmanager_secrets" "secrets" {
#   for_each = toset(local.secrets_path_filter)
#   filter {
#     name   = "name"
#     values = [each.value]
#   }
# }

data "google_secret_manager_secrets" "secrets" {
  for_each = toset(local.secrets_path_filter)
  filter   = format("name:%s", each.value)
}

data "google_secret_manager_secret_version" "secret" {
  for_each = local.secrets_map
  secret   = each.value.secret_name
}

locals {
  secrets_map_pre = merge([
    for prefix in toset(local.secrets_path_filter) : {
      for secret_object in data.google_secret_manager_secrets.secrets[prefix].secrets : secret_object.name => {
        secret_name  = secret_object.name
        prefix       = prefix
        filtered_key = replace(replace(secret_object.name, "/", "|"), replace(format("%s", prefix), "/", "|"), "")
        splitted_key = split("/", secret_object.name)
      }
    }
  ]...)

  secrets_map = {
    for key, value in local.secrets_map_pre : key => {
      secret_name  = value.secret_name
      prefix       = value.prefix
      filtered_key = replace(replace((value.filtered_key != "" ? value.filtered_key : value.splitted_key[(length(value.splitted_key) - 1)]), "-", "_"), "/^[-_|]+/", "")
    }
  }

  secrets_plain = {
    for key, value in local.secrets_map : value.filtered_key => data.google_secret_manager_secret_version.secret[key].secret_data
    if !startswith(data.google_secret_manager_secret_version.secret[key].secret_data, "{")
  }

  secrets_json = merge([
    for key, secret in local.secrets_map : {
      for ent, value in tomap(jsondecode(data.google_secret_manager_secret_version.secret[key].secret_data)) :
      "${lower(secret.filtered_key)}_${lower(ent)}" => value
    }
    if startswith(data.google_secret_manager_secret_version.secret[key].secret_data, "{")
  ]...)

  all_secrets_map = merge(local.secrets_plain, local.secrets_json)
}

resource "kubernetes_secret" "secrets" {
  count = length(local.secrets_path_filter) > 0 && !local.external_secrets_enabled ? 1 : 0
  metadata {
    name      = "${var.release.name}-injected-secrets"
    namespace = var.create_namespace ? kubernetes_namespace.this[0].metadata.0.name : data.kubernetes_namespace.this[0].metadata.0.name
  }
  data = local.all_secrets_map
}