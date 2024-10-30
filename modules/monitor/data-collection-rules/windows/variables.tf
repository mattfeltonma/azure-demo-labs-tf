variable "data_collection_endpoint_id" {
    description = "The id of the data collection endpoint to associate the data collection rule with"
    type        = string
}

variable "location" {
    description = "The location to the deploy data collection endpoint"
    type        = string
}

variable "law_name" {
  description = "The name of the Log Analytics Workspace to associate the data collection rule with"
  type        = string
}

variable "law_resource_id" {
  description = "The resource id of the Log Analytics Workspace to associate the data collection rule with"
  type        = string
}

variable "purpose" {
    description = "The purpose of the data collection rule"
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