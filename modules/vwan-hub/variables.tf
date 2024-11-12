variable "address_space" {
  description = "The address space to assign to the Virtual WAN Hub"
  type        = string
}

variable "law_resource_id" {
  description = "The resource id of the Log Analytics Workspace"
  type        = string
}

variable "location" {
  description = "The location the resource will be deployed to"
  type        = string
}

variable "location_code" {
  description = "The code for the location the resource will be deployed to"
  type        = string
}

variable "random_string" {
  description = "The random string to append to the resource name"
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
