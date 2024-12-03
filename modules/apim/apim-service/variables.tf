variable "dns_label" {
  description = "The custom dns label to add to the public IP as is required by an internal mode API Management"
  type        = string
  default = null
}

variable "key_vault_id" {
  description = "The Key Vault resource id the API Management instance will have access to"
  type        = string
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

variable "publisher_name" {
  description = "The name of the publisher to display in the Azure API Management instance"
  type = string
}

variable "publisher_email" {
  description = "The email address of the publisher to display in the Azure API Management instance"
  type = string
}

variable "purpose" {
  description = "The three character purpose of the resource"
  type        = string
}

variable "random_string" {
  description = "The random string to append to the resource name"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the resources to"
  type        = string
}

variable "subnet_id" {
  description = "The subnet id to deploy the Azure API Management instance to"
  type        = string
}

variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}
