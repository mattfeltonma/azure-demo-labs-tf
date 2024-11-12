variable "address_space_azure" {
  description = "The address space assigned to Azure"
  type        = string
}

variable "address_space_onpremises" {
  description = "The address space assigned to on-premises"
  type        = string
}

variable "address_space_vnet" {
  description = "The address space assigned to virtual network"
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
  default     = ["168.63.129.16"]
}

variable "dns_proxy" {
  description = "Whether a DNS proxy is being used"
  type        = bool
  default     = false
}

variable "fw_private_ip" {
  description = "The private IP address of the Azure Firewall"
  type        = string
  default     = null
}

variable "hub_and_spoke" {
  description = "Whether the virtual network is a hub-and-spoke topology"
  type        = bool
  default     = true
}

variable "law_resource_id" {
  description = "The resource id of the Log Analytics Workspace to send diagnostic logs to"
  type        = string
}

variable "law_workspace_id" {
  description = "The workspace id of the Log Analytics Workspace to send vnet flow logs to"
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

variable "location_code" {
  description = "The location code to append to the resource name"
  type        = string
}

variable "name_hub" {
  description = "The name of the hub virtual network"
  type        = string
  default = null
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
  default = null
}

variable "sku_tools_size" {
  description = "The VM SKU size of the virtual machine to deploy to the tools subnet"
  type        = string
}

variable "sku_tools_os" {
  description = "The SKU of the operating system to deploy to the tools subnet"
  type        = string
}

variable "storage_account_id_flow_logs" {
  description = "The resource id of the storage account to send virtual network flow logs to"
  type        = string
}

variable "subnet_cidr_bastion" {
  description = "The address space to assign to the Azure Bastion subnet"
  type        = string
}

variable "subnet_cidr_dnsin" {
  description = "The address space to assign to the subnet delegated to the inbound DNS resolver"
  type        = string
}

variable "subnet_cidr_dnsout" {
  description = "The address space to assign to the subnet delegated to the outbound DNS resolver"
  type        = string
}

variable "subnet_cidr_pe" {
  description = "The address space to assign to the private endpoint subnet"
  type        = string
}

variable "subnet_cidr_tools" {
  description = "The address space to assign to the tools subnet"
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
  description = "The resource id of the hub virtual network this virtual network will be peered to"
  type        = string
  default     = null
}

variable "vwan_associated_route_table" {
  description = "The resource id of the route table the virtual network connection will be associated with"
  type        = string
  default     = null
}

variable "vwan_hub_id" {
  description = "The resource id of the VWAN hub this virtual network will be connected to"
  type        = string
  default     = null
}

variable "vwan_propagate_default_route" {
    description = "Propagate the default route to the connected virtual network"
    type        = bool
    default     = false
}

variable "vwan_propagate_route_labels" {
    description = "The VWAN route table labels to propagate the virtual network CIDR block to"
    type        = list(string)
    default     = []
}

variable "vwan_propagate_route_tables" {
    description = "The VWAN route tables to propagate the virtual network CIDR block to"
    type        = list(string)
    default     = []
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

variable "vwan_static_routes" {
    description = "The static routes to create on the virtual network connection to the VWAN Hub"
    type = list(object({
        name                = string
        address_prefixes    = list(string)
        next_hop_ip_address = string
    }))
    default = []
}


