variable "location" {
  description = "The name of the location to provision the resources to"
  type        = string
}

variable "location_code" {
  description = "The location code to append to the resource name"
  type = string
}

variable "private_dns_zone_ids" {
  description = "The ids of the private dns zones to link to the private endpoint for lifecycle management of the DNS records"
  type        = list(string)
}

variable "resource_name" {
  description = "The the resource name the pe will be connected to"
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

variable "resource_id" {
  description = "The resource id of the resource the private endpoint will connect to"
  type        = string
}

variable "subresource_name" {
  description = "The subresource name of the resource the private endpoint will connect to"
  type        = string
}

variable "subnet_id" {
  description = "The id of the subnet to deploy the private endpoint to"
  type        = string
}


variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}
