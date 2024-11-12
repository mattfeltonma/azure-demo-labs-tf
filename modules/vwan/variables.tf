variable "allow-branch" {
    description = "Allow branch-to-branch traffic"
    type        = bool
    default = true
}

variable "location" {
  description = "The name of the location to deploy the resource to"
  type        = string
}

variable "location_code" {
  description = "The location code to append to the resource name"
  type = string
}

variable "random_string" {
  description = "The random string to append to the virtual network gateway name"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the resource to"
  type        = string
}

variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}
