variable "location" {
  description = "The name of the location to deploy the resources to"
  type        = string
}

variable "location_code" {
  description = "The location code to append to the resource name"
  type = string
}

variable "law_resource_id" {
  description = "The resource id of the log analytics workspace to send diagnostic logs to"
  type        = string
}

variable "purpose" {
  description = "Three character code to identify the purpose of the resource"
  type        = string
}

variable "random_string" {
  description = "The random string to append to the resource name"
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the resources to"
  type        = string
}

variable "security_rules" {
  description = "The security rules to apply to the resource"
  type = list(object({
    name                         = string
    description                  = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = string
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
  }))
}

variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}

