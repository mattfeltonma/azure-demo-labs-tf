variable "location" {
  description = "The name of the location to deploy the resource to"
  type        = string
}

variable "name" {
  description = "The name of the virtual wan"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the resource to"
  type        = string
}

variable "site_asn" {
  description = "The ASN of the VPN site"
  type        = string
}

variable "site_bgp_ip_address" {
  description = "The IP address used for BGP peering at the VPN site"
  type        = string
}

variable "site_public_ip_address" {
  description = "The public IP address of the VPN site"
  type        = string
}

variable "tags" {
  description = "The tags to apply to the resource"
  type        = map(string)
}

variable "vwan_id" {
  description = "The resource id of the Virtual WAN the Virtual WAN Hub is associated with"
  type        = string
}
