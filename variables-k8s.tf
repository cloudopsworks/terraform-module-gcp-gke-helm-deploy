##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

variable "namespace" {
  description = "Namespace for the resources"
  type        = string
}

# variable "repository_owner" {
#   description = "Owner of the repository"
#   type        = string
# }

variable "release" {
  description = "Release configuration"
  type        = any
  default     = {}
}
# variable "cluster_name" {
#   description = "Name of the EKS cluster"
#   type        = string
# }

variable "helm_repo_url" {
  description = "URL of the Helm repository"
  type        = string
  default     = ""
}

variable "helm_chart_name" {
  description = "Name of the Helm chart"
  type        = string
  default     = ""
}

variable "helm_chart_path" {
  description = "Path to the Helm chart"
  type        = string
  default     = ""
}

variable "values_file" {
  description = "Path to the values file"
  type        = string
}

variable "values_overrides" {
  description = "Values to be passed to the Helm chart"
  type        = any
  default     = {}
}

variable "absolute_path" {
  description = "Absolute path of the current directory"
  type        = string
  default     = "."
}

variable "config_map" {
  description = "ConfigMap to be created"
  type        = any
  default     = {}
}

variable "secret_files" {
  description = "Secret files to be injected into a folder alongside with 'secrets' variable templating"
  type        = any
  default     = {}
}

# Documentation for the secrets variable - YAML
# secrets:
#   secrets_path_filter: [] List of secrets to be pulled from AWS Secrets Manager
#   external_secrets:                 # If Enabled, secrets path filter will be used to configure the External Secrets Store for automatically fetching secrets from AWS Secrets Manager
#     enabled: true | false                 # Optional: set this to true if you want to use the External Secrets Store, defaults to false
#     create_store: true | false            # Optional: set this if you want to create the External Secrets Store
#     store_name: "external-secrets-store"  # Optional: set this if you want to use an existing External Secrets Store, valid only if create_store is false
#     refresh_interval: "1h"                # Optional: set this to change the refresh interval of the External Secrets Store
#     on_change: true | false               # Optional: set this to true if you want to trigger the deployment on change of the secrets
variable "secrets" {
  description = "Secrets to be pulled from AWS Secrets Manager"
  type        = any
  default     = {}
}

variable "create_namespace" {
  description = "Create the namespace if it does not exist"
  type        = bool
  default     = false
}

variable "namespace_annotations" {
  description = "Annotations for the namespace"
  type        = any
  default     = {}
}

variable "region" {
  description = "Region location for the resources"
  type        = string
}