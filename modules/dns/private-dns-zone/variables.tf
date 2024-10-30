variable "name" {
  description = "The DNS namespace the zone will host"
  type        = string
}

variable "registration_enabled" {
  description = "Is auto-registration enabled for this private dns zone"
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "The name of the resource group the resource will be deployed to"
  type        = string
}

variable "vnet_id" {
  description = "The id of the virtual network to link the private dns zone to"
  type        = string
}
variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}