variable "location" {
  description = "The name of the location to deploy the resources to"
  type = string
}

variable "purpose" {
  description = "Three character code to identify the purpose of the resource"
  type = string
}

variable "random_string" {
  description = "The random string to append to the resource name"
  type = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the resources to"
  type = string
}

variable "retention_in_days" {
  description = "The retention in days for the log analytics workspace"
  type = number
  default = 30
}

variable "tags" {
  description = "The tags to apply to the resource"
  type = map(string)
}