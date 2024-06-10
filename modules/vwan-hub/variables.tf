variable "address_space" {
  description = "The address space to assign to the Virtual WAN Hub"
  type        = string
}

variable "law_resource_id" {
  description = "The resource id of the Log Analytics Workspace"
  type        = string
}

variable "location" {
  description = "The name of the location to deploy the resource to"
  type        = string
}

variable "name" {
  description = "The name of the virtual wan"
  type        = string
}

variable "routing_preference" {
  description = "The routing preference for the Virtual WAN Hub"
  type        = string
  default     = "ExpressRoute"
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the resource to"
  type        = string
}

variable "sku" {
  description = "The SKU of the Virtual WAN Hub"
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}

variable "vpn_gateway" {
  description = "Specifies whether a VPN Gateway should be created"
  type        = bool
}

variable "vwan_id" {
  description = "The resource id of the Virtual WAN the Virtual WAN Hub is associated with"
  type        = string
}
