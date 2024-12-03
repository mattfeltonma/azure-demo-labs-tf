variable "dns_label" {  
  description = "The resource id of the Log Analytics Workspace to send diagnostic logs to"
  type        = string
  default = null
}

variable "law_resource_id" {  
  description = "The resource id of the Log Analytics Workspace to send diagnostic logs to"
  type        = string
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
  description = "The three character purpose code to append to the resource name"
  type        = string
}

variable "random_string" {
  description = "The random string to include in the resource name"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the resources to"
  type        = string
}

variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}
