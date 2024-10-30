variable "bgp_route_propagation_enabled" {
  description = "Enable BGP route propagation"
  type        = bool
  default    = true
}

variable "location" {
  description = "The name of the location to provision the resources to"
  type        = string
}

variable "location_code" {
  description = "The location code to append to the resource name"
  type = string
}

variable "purpose" {
  description = "The three character code to identify the purpose of the resource"
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

variable "routes" {
  description = "The routes to add to the route table"
  type        = list(object({
    name                 = string
    address_prefix    = string
    next_hop_type = string
    next_hop_in_ip_address = optional(string)
  }))
}

variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}
