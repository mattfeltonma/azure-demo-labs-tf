variable "location" {
  description = "The location of the resource"
  type        = string
}

variable "random_string" {
  description = "The random string to append to the resource name"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group the resource will be deployed to"
  type        = string
}

variable "subnet_id_inbound" {
  description = "The id of the subnet to deploy the inbound resolver endpoint to"
  type        = string
}

variable "subnet_id_outbound" {
  description = "The id of the subnet to deploy the outbound resolver endpoint to"
  type        = string
}

variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}

variable "vnet_id" {
  description = "The resource id of the virtual network the resolver will be deployed to"
  type        = string
}