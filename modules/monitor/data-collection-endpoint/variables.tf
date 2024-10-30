variable "location" {
    description = "The location to the deploy data collection endpoint"
    type        = string
}

variable "location_code" {
    description = "The location code"
    type        = string
}

variable "purpose" {
    description = "The purpose of the data collection endpoint"
    type        = string
}

variable "random_string" {
    description = "The random string to append to the resource"
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