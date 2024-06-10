variable "location" {
  description = "The name of the location to deploy the resources to"
  type = string
}

variable "purpose" {
  description = "The three character purpose code for the resource"
  type = string
}

variable "random_string" {
  description = "The random string to append to the resource name"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the resources to"
  type = string
}

variable "tags" {
  description = "The tags to apply to the resource"
  type = map(string)
}