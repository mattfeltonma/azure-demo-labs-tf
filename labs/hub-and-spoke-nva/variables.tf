variable "address_space_onpremises" {
  description = "The address space used on-premises"
  type        = string
}
 
variable "address_space_cloud" {
  description = "The address space in the cloud"
  type        = string
}

variable "address_space_azure_primary_region" {
  description = "The address space in the primary Azure region"
  type        = string
}

variable "address_space_azure_secondary_region" {
  description = "The address space in the secondary Azure region"
  type        = string
  default = null
}

variable "admin_username" {
  description = "The username to assign to the virtual machine"
  type        = string
}

variable "admin_password" {
  description = "The password to assign to the virtual machine"
  type        = string
  sensitive   = true
}

variable "key_vault_admin" {
  description = "The object id of the user or service principal to assign the Key Vault Administrator role to"
  type        = string

}

variable "location_primary" {
  description = "The primary location to deploy resources to"
  type        = string
}

variable "location_secondary" {
  description = "The secondary location to deploy resources to"
  type        = string
  default = null
}

variable "multi_region" {
  description = "Whether to deploy resources in multiple regions"
  type        = bool
  default     = false
}

variable "network_watcher_name" {
  description = "The name of the network watcher resource"
  type        = string
  default     = "NetworkWatcher_"
}

variable "network_watcher_resource_group_name" {
  description = "The name of the network watcher resource group"
  type        = string
  default     = "NetworkWatcherRG"
}

variable "private_dns_namespaces" {
  description = "The private DNS zones to create and link to the shared services virtual network"
  type        = list(string)
  default = [
    "privatelink.azurecr.io",
    "privatelink.database.windows.net",
    "privatelink.blob.core.windows.net",
    "privatelink.queue.core.windows.net",
    "privatelink.table.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.dfs.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.azurewebsites.net",
    "privatelink.servicebus.windows.net",
    "privatelink.eventgrid.azure.net",
    "privatelink.cosmos.azure.com",
    "privatelink.openai.azure.com",
    "privatelink.notebooks.azure.net",
    "privatelink.api.azureml.ms",
    "privatelink.cognitiveservices.azure.com",
  ]
}

variable "sku_vm_size" {
  description = "The SKU to use for virtual machines created"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "sku_tools_os" {
  description = "The operating system to use for the tools virtual machine"
  type        = string
  default     = "2019-datacenter-gensecond"
}

variable "tags" {
  description = "The tags to apply to the resources"
  type        = map(string)
}