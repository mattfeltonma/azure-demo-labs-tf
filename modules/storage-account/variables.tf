variable "law_resource_id" {
  description = "The resource id of the Log Analytics Workspace"
  type = string
}

variable "location" {
  description = "The name of the location to deploy the resources to"
  type = string
}

variable "purpose" {
  description = "The three-letter purpose code for the resource"
  type = string
}

variable "network_access_default" {
  description = "The default network access to apply to the storage account"
  type = string
  default = "Deny"
}

variable "network_trusted_services_bypass" {
  description = "The trusted services to bypass the network"
  type = list(string)
  default = [
    "AzureServices",
    "Logging",
    "Metrics"
  ]
}

variable "random_string" {
  description = "The random string to append to the resource name"
  type = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the resources to"
  type = string
}

variable "storage_account_kind" {
  description = "The kind of storage account to create"
  type = string
  default = "StorageV2"
}

variable "storage_account_replication_type" {
  description = "The replication type to apply to the storage account"
  type = string
  default = "LRS"
}

variable "storage_account_tier" {
  description = "The tier of the storage account to create"
  type = string
  default = "Standard"
}

variable "tags" {
  description = "The tags to apply to the resource"
  type = map(string)
}