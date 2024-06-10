variable "data_collection_endpoint_id" {
  description = "The resource id of the Data Collection Endpoint to associate the data collection rule with"
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

variable "name" {
    description = "The name of the data collection endpoint"
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