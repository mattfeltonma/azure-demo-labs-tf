variable "address_space_azure" {
  description = "The address space used in the Azure environment"
  type        = string
}

variable "address_space_apim" {
  description = "The CIDR block the internally-facing APIM instance is deployed to"
  type        = string
}

variable "address_space_onpremises" {
  description = "The address space used on-premises"
  type        = string
}

variable "dns_servers" {
  description = "The DNS Servers the Azure Firewall should use for DNS resolution"
  type        = list(string)
  default     = ["168.63.129.16"]
}

variable "dns_cidr" {
  description = "The CIDR block of the subnet used to host DNS services in Azure"
  type        = string
}

variable "firewall_subnet_id" {
  description = "The subnet id to associate to the firewall"
  type        = string
  default     = null
}

variable "hub_and_spoke" {
  description = "Whether the deployment is hub and spoke"
  type        = bool
  default     = true
}

variable "law_resource_id" {
  description = "The resource id of the Log Analytics Workspace to send diagnostic logs to"
  type        = string
}

variable "law_workspace_region" {
  description = "The region the Log Analytics Workspace is deployed to"
  type        = string
}

variable "location" {
  description = "The name of the location to provision the resources to"
  type        = string
}

variable "location_code" {
  description = "The location code to append to the resource name"
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

variable "sku_name" {
  description = "The name of the Azure Firewall SKU to use which is either AZFW_Vne or AZFW_Hub"
  type        = string
  default     = "AZFW_VNet"
}

variable "sku_tier" {
  description = "The tier of the Azure Firewall"
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}

variable "vwan_hub_id" {
  description = "The id of the virtual wan hub the Azure Firewall instance will be provisioned to"
  type        = string
  default     = null
}

