variable "location_primary" {
  description = "The primary location where the Log Analytics Workspace and Data Collection Rules and a regionally-specific Data Collection Endpoint will be deployed to"
  type = string
}

variable "location_secondary" {
  description = "The secondary location where a regionally specific data collection endpoint will be deployed to"
  type = string
  default = null
}

variable "location_code_primary" {
    description = "The location code for the primary region"
    type        = string
}

variable "location_code_secondary" {
    description = "The location code for the secondary region"
    type        = string
    default = null
}


variable "purpose" {
  description = "Three character code to identify the purpose of the resource"
  type = string
}

variable "random_string" {
  description = "The random string to append to the resource name"
  type = string
}

variable "resource_group_name_primary" {
  description = "The name of the resource group to deploy the resources to"
  type = string
}

variable "resource_group_name_secondary" {
  description = "The name of the resource group to deploy the resources to"
  type = string
  default = null
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