variable "user_object_id" {
  description = "The object id of the user who will manage the AI Studio Hub"
  type        = string
}

variable "location" {
  description = "The name of the location to provision the resources to"
  type        = string
}

variable "purpose" {
  description = "The three character purpose of the resource"
  type        = string
}

variable "random_string" {
  description = "The random string to append to the resource name"
  type        = string
}

variable "resource_group_name_dns" {
  description = "The name of the resource group where the Private DNS Zones exist"
  type        = string
}

variable "sub_id" {
  description = "The subscription where the Private DNS Zones are located"
  type        = string
}

variable "subnet_id" {
  description = "The subnet id to deploy the private endpoints to"
  type        = string
}

variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}

variable "workload_vnet_location" {
  description = "The region where the workload virtual network is located"
  type        = string
}
