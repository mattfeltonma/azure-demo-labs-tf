variable "address_space_vnet" {
  description = "The address space to assign to the virtual network"
  type        = string
}

variable "dns_servers" {
  description = "The DNS Servers to configure for the virtual network"
  type        = list(string)
  default     = ["168.63.129.16"]
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

variable "vwan_associated_route_table" {
  description = "The resource id of the route table the virtual network connection will be associated with"
  type        = string
  default     = null
}

variable "vwan_hub_id" {
  description = "The resource id of the VWAN hub this virtual network will be connected to"
  type        = string
}

variable "vwan_propagate_default_route" {
  description = "Propagate the default route to the connected virtual network"
  type        = bool
  default     = false
}

variable "vwan_propagate_route_labels" {
  description = "The VWAN route table labels to propagate the virtual network CIDR block to"
  type        = list(string)
  default     = null
}

variable "vwan_propagate_route_tables" {
  description = "The VWAN route tables to propagate the virtual network CIDR block to"
  type        = list(string)
  default     = null
}

variable "vwan_inbound_route_map_id" {
  description = "The resource id of the inbound route map to apply to the virtual network connection"
  type        = string
  default     = null
}

variable "vwan_outbound_route_map_id" {
  description = "The resource id of the outbound route map to apply to the virtual network connection"
  type        = string
  default     = null
}

variable "vwan_secure_hub" {
  description = "The virtual network will be connected to a VWAN Secure Hub with routing intent enabled"
  type        = string
  default     = false
}

variable "vwan_static_routes" {
  description = "The static routes to create on the virtual network connection to the VWAN Hub"
  type = list(object({
    name                = string
    address_prefixes    = list(string)
    next_hop_ip_address = string
  }))
  default = []
}


