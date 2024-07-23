variable "address_space_apim" {
  description = "The address space used for the APIM subnet"
  type        = string
}

variable "address_space_azure" {
  description = "The address space used in the Azure environment"
  type        = string
}

variable "address_space_onpremises" {
  description = "The address space used on-premises"
  type        = string
}

variable "address_space_vnet" {
  description = "The address space to assign to the virtual network"
  type        = list(string)
}

variable "dns_servers" {
  description = "The DNS Servers to configure for the virtual network"
  type        = list(string)
  default    = ["168.63.129.16"]
}

variable "location" {
  description = "The name of the location to provision the resources to"
  type        = string
}

variable "network_watcher_resource_id" {
  description = "The resource id of the Network Watcher to send vnet flow logs to"
  type        = string
}

variable "random_string" {
  description = "The random string to append to the resource name"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the resources to"
  type        = string
}

variable "storage_account_id_flow_logs" {
  description = "The resource id of the storage account to send virtual network flow logs to"
  type        = string
}

variable "subnet_cidr_dns" {
  description = "The address space to assign to the subnet hosting the DNS servers"
  type        = string
}

variable "subnet_cidr_firewall" {
  description = "The address space to assign to the subnet delegated to the inbound DNS resolver"
  type        = list(string)
}

variable "subnet_cidr_gateway" {
  description = "The address space to assign to the Azure Bastion subnet"
  type        = list(string)
}

variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}

variable "traffic_analytics_workspace_guid" {
  description = "The workspace guid to send traffic analytics to"
  type        = string
}

variable "traffic_analytics_workspace_location" {
  description = "The workspace region to send traffic analytics to"
  type        = string
}

variable "traffic_analytics_workspace_id" {
  description = "The workspace resource id send traffic analytics to"
  type        = string
}

variable "vnet_cidr_ss" {
  description = "The address space to assign to the shared services virtual network"
  type        = string
}

variable "vnet_cidr_wl" {
  description = "The address space to assign to the workload virtual network"
  type        = string
}