variable "address_space_vnet" {
  description = "The address space to assign to the virtual network"
  type        = list(string)
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

variable "dce_id" {
  description = "The resource id of the Data Collection Endpoint"
  type        = string
}

variable "dcr_id_windows" {
  description = "The resource id of the Data Collection Rule for Windows"
  type        = string
}

variable "dns_servers" {
  description = "The DNS Servers to configure for the virtual network"
  type        = list(string)
  default    = ["168.63.129.16"]
}

variable "law_resource_id" {
  description = "The resource id of the Log Analytics Workspace to send diagnostic logs to"
  type        = string
}

variable "location" {
  description = "The name of the location to provision the resources to"
  type        = string
}

variable "network_watcher_resource_id" {
  description = "The resource id of the Network Watcher to send vnet flow logs to"
  type        = string
}

variable "private_dns_namespaces" {
  description = "The private DNS zones to create and link to the shared services virtual network"
  type        = list(string)
}

variable "random_string" {
  description = "The random string to append to the resource name"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the resources to"
  type        = string
}

variable "sku_tools_os" {
  description = "The SKU of the operating system to deploy to the tools subnet"
  type        = string
}

variable "sku_tools_size" {
  description = "The VM SKU size of the virtual machine to deploy to the tools subnet"
  type        = string
}

variable "storage_account_id_flow_logs" {
  description = "The resource id of the storage account to send virtual network flow logs to"
  type        = string
}

variable "sub_id" {
  description = "The subscriptions resources are deployed to"
  type        = string
}

variable "subnet_cidr_agw" {
  description = "The address space to assign to the subnet used for the Application Gateway"
  type        = list(string)
}

variable "subnet_cidr_apim" {
  description = "The address space to assign to the subnet used for the API Management instance"
  type        = list(string)
}

variable "subnet_cidr_app" {
  description = "The address space to assign to the subnet used for the application tier"
  type        = list(string)
}

variable "subnet_cidr_data" {
  description = "The address space to assign to the subnet used for the data tier"
  type        = list(string)
}

variable "subnet_cidr_mgmt" {
  description = "The address space to assign to the subnet used for management services"
  type        = list(string)
}

variable "subnet_cidr_svc" {
  description = "The address space to assign to the subnet used for services exposed by Private Endpoints"
  type        = list(string)
}

variable "subnet_cidr_tool" {
  description = "The address space to assign to the subnet used for virtual machines running tools"
  type        = list(string)
}

variable "subnet_cidr_vint" {
  description = "The address space to assign to the subnet used for virtual network integration"
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


