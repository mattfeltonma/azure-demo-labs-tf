variable "address_space_vnet" {
  description = "The address space to assign to the virtual network"
  type        = list(string)
}

variable "dns_servers" {
  description = "The address space to assign to the Private Endpoint subnet"
  type        = list(string)
  default    = ["168.63.129.16"]
}

variable "law_resource_id" {
  description = "The resource id of the Log Analytics Workspace to send diagnostic logs to"
  type        = string
}

variable "law_workspace_id" {
  description = "The workspace id of the Log Analytics Workspace to send NSG flow logs to"
  type        = string
}

variable "law_workspace_region" {
  description = "The region the Log Analytics Workspace is deployed to"
  type        = string
}

variable "location" {
  description = "The name of the location to provision the resources to"
  type        = string
}

variable "name" {
  description = "The name of the virtual network"
  type        = string
}

variable "network_watcher_name" {
  description = "The name of the Network Watcher to send NSG flow logs to"
  type        = string
}

variable "network_watcher_resource_group_name" {
  description = "The name of the resource group the Network Watcher is deployed to"
  type        = string
}

variable "region_number" {
  description = "The region number to append to the resource name"
  type        = string
  default = "1"
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the resources to"
  type        = string
}

variable "storage_account_id_flow_logs" {
  description = "The resource id of the storage account to send NSG flow logs to"
  type        = string
}

variable "subnet_cidr_bastion" {
  description = "The address space to assign to the Bastion subnet"
  type        = list(string)
}

variable "subnet_cidr_dnsin" {
  description = "The address space to assign to the Private DNS Resolver Inbound Endpoint"
  type        = list(string)
}

variable "subnet_cidr_dnsout" {
  description = "The address space to assign to the Private DNS Resolver Outbound Endpoint"
  type        = list(string)
}

variable "subnet_cidr_pe" {
  description = "The address space to assign to the private endpoint subnet"
  type        = list(string)
}

variable "subnet_cidr_tools" {
  description = "The address space to assign to the tools subnet"
  type        = list(string)
}

variable "subnet_cidr_bastion" {
  description = "The address space to assign to the Bastion subnet"
  type        = list(string)
}

variable "subnet_name_dnsin" {
  description = "The name to assign to the Private DNS Resolver Inbound Endpoint"
  type        = string
  default = "snet-dnsin"
}

variable "subnet_name_dnsout" {
  description = "The name to assign to the Private DNS Resolver Outbound Endpoint"
  type        = string
  default = "snet-dnsout"
}

variable "subnet_name_pe" {
  description = "The name to assign to the private endpoint subnet"
  type        = string
  default = "snet-pe"
}

variable "subnet_name_tools" {
  description = "The name to assign to the tools subnet"
  type        = string
  default = "snet-tools"
}

variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}