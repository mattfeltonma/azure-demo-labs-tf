variable "associated_route_table" {
  description = "The id of the route table the virtual network connection be associated with"
  type        = string
  default = null
}

variable "hub_id" {
  description = "The resource id of the VWAN Hub the virtual network will be connected to"
  type        = string
}

variable "inbound_route_map_id" {
  description = "The resource id of the inbound route map to apply to the virtual network connection"
  type        = string
  default = null
}

variable "outbound_route_map_id" {
  description = "The resource id of the outbound route map to apply to the virtual network connection"
  type        = string
  default = null
}

variable "propagate_default_route" {
  description = "The default route should be propagated to this virtual network"
  type = bool
  default = true
}

variable "propagate_route_labels" {
  description = "The labels the virtual network will propagate to the VWAN Hub"
  type = list(string)
  default = null
}

variable "propagate_route_tables" {
  description = "The route tables the virtual network will propagate to the VWAN Hub"
  type = list(string)
  default = null
}

variable "secure_hub" {
    description = "The connection is being made to a secure hub"
    type = bool
    default = false
}

variable "static_routes" {
  description = "The static routes to create on the virtual network connection to the VWAN Hub"
  type = list(object({
    name = string
    address_prefixes = list(string)
    next_hop_ip_address = string
  }))
  default = null
}

variable "vnet_id" {
  description = "The resource id of the virtual network to connect to the VWAN Hub"
  type        = string
}

variable "vnet_name" {
  description = "The name of the virtual network to connect to the VWAN Hub"
  type        = string
}

