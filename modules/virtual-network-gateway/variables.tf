variable "law_resource_id" {  
  description = "The resource id of the Log Analytics Workspace to send diagnostic logs to"
  type        = string
}

variable "location" {
  description = "The location to deploy the virtual network gateway"
  type        = string
}

variable "location_code" {
  description = "The location code to append to the resource name"
  type = string
}

variable "purpose" {
  description = "The three character purpose code for the virtual network gateway"
  type        = string

}

variable "random_string" {
  description = "The random string to append to the virtual network gateway name"
  type        = string

}
variable "resource_group_name" {
  description = "The name of the resource group to deploy the virtual network gateway"
  type        = string
}

variable "sku" {
  description = "The SKU of the virtual network gateway"
  type        = string
  default = "VpnGw1"

}

variable "subnet_id_gateway" {
  description = "The subnet id to deploy the virtual network gateway to"
  type        = string
}

variable "tags" {
  description = "The tags to apply to the virtual network gateway"
  type        = map(string)
}
