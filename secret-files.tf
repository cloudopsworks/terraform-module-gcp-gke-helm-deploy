##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  secret_files_path           = try(var.secret_files.files_path, "")
  secret_config_path          = local.secret_files_path != "" ? format("%s/%s", local.values_path, local.secret_files_path) : local.values_path
  secret_files_in_config_path = try(var.secret_files.enabled, false) == true ? fileset(local.secret_config_path, "*") : []
  secret_index                = local.configmap_enabled ? 1 : 0
  secret_enabled              = try(var.secret_files.mount_point, "") != "" && try(var.secret_files.enabled, false) == true
  secret_mount_overrides = local.secret_enabled ? zipmap(
    [
      "injectedVolumes[${local.secret_index}].name",
      "injectedVolumes[${local.secret_index}].secret.secretName",
      "injectedVolumeMounts[${local.secret_index}].name",
      "injectedVolumeMounts[${local.secret_index}].mountPath",
    ],
    [
      "${var.release.name}-injected-secret-files",
      "${var.release.name}-injected-secret-files",
      "${var.release.name}-injected-secret-files",
      var.secret_files.mount_point,
    ]
  ) : {}
}

resource "kubernetes_secret" "secret_files" {
  count = try(var.secret_files.enabled, false) == true && length(local.secret_files_in_config_path) > 0 ? 1 : 0
  metadata {
    name      = "${var.release.name}-injected-secret-files"
    namespace = var.create_namespace ? kubernetes_namespace.this[0].metadata.0.name : data.kubernetes_namespace.this[0].metadata.0.name
    labels = {
      "app.kubernetes.io/name"       = var.release.name
      "app.kubernetes.io/version"    = local.release_version
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }
  data = {
    for file in local.secret_files_in_config_path : file => templatefile("${local.secret_config_path}/${file}", local.all_secrets_map)
    if !contains([".empty", ".placeholder"], file)
  }
}


