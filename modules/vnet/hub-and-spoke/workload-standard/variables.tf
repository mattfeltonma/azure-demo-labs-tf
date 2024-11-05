variable "address_space_vnet" {
  description = "The address space to assign to the virtual network"
  type        = string
}

variable "dns_servers" {
  description = "The DNS Servers to configure for the virtual network"
  type        = list(string)
  default    = ["168.63.129.16"]
}

variable "fw_private_ip" {
  description = "The private IP address of the Azure Firewall"
  type        = string
}

variable "law_resource_id" {
  description = "The resource id of the Log Analytics Workspace to send diagnostic logs to"
  type        = string
}

variable "location" {
  description = "The name of the location to provision the resources to"
  type        = string
}

variable "location_code" {
  description = "The location code to append to the resource name"
  type = string
}

variable "name_hub" {
  description = "The name of the hub virtual network"
  type        = string
}

variable "name_shared" {
  description = "The name of the shared virtual network"
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

variable "resource_group_name_hub" {
  description = "The name of the resource group the hub virtual network is deployed to"
  type        = string
}

variable "resource_group_name_shared" {
  description = "The name of the resource group the shared services virtual network is deployed to"
  type        = string
}

variable "storage_account_id_flow_logs" {
  description = "The resource id of the storage account to send virtual network flow logs to"
  type        = string
}

variable "sub_id_shared" {
  description = "The subscription id of the shared services virtual network"
  type        = string
}

variable "subnet_cidr_agw" {
  description = "The address space to assign to the subnet used for the Application Gateway"
  type        = string
}

variable "subnet_cidr_apim" {
  description = "The address space to assign to the subnet used for the API Management instance"
  type        = string
}

variable "subnet_cidr_app" {
  description = "The address space to assign to the subnet used for the application tier"
  type        = string
}

variable "subnet_cidr_data" {
  description = "The address space to assign to the subnet used for the data tier"
  type        = string
}

variable "subnet_cidr_mgmt" {
  description = "The address space to assign to the subnet used for management services"
  type        = string
}

variable "subnet_cidr_svc" {
  description = "The address space to assign to the subnet used for services exposed by Private Endpoints"
  type        = string
}

variable "subnet_cidr_vint" {
  description = "The address space to assign to the subnet used for virtual network integration"
  type        = string
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

variable "vnet_id_hub" {
  description = "The resource id of the hub virtual network"
  type        = string
}


