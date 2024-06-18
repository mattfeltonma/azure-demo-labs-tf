variable "address_space_onpremises" {
  description = "The address space used on-premises"
  type        = string
}

variable "address_space_azure" {
  description = "The address space used in Azure"
  type        = string
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

variable "network_watcher_name" {
  description = "The name of the network watcher resource"
  type        = string
  default    = "NetworkWatcher_"
}

variable "network_watcher_resource_group_name" {
  description = "The name of the network watcher resource group"
  type        = string
  default     = "NetworkWatcherRG"
}

variable "location" {
  description = "The region to deploy resources to"
  type        = string
}

variable "private_dns_namespaces" {
  description = "The private DNS zones to create and link to the shared services virtual network"
  type        = list(string)
  default    = [
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
    "privatelink.openai.azure.com"
  ]
}

variable "sku_tools_size" {
  description = "The SKU to use for the tools virtual machine"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "sku_tools_os" {
  description = "The operating system to use for the tools virtual machine"
  type        = string
  default     = "2019-Datacenter"
}

variable "tags" {
  description = "The tags to apply to the resources"
  type        = map(string)
}

variable "vnet_cidr_ss" {
  description = "The virtual network CIDR block for the shared services virtual network"
  type        = string
  default = "10.51.0.0/16"
}

variable "vnet_cidr_tr" {
  description = "The virtual network CIDR block for the transit services virtual network"
  type        = string
  default = "10.50.0.0/16"
}

variable "vnet_cidr_wl" {
  description = "The virtual network CIDR block for the workload virtual network"
  type        = string
  default = "10.52.0.0/16"
}
