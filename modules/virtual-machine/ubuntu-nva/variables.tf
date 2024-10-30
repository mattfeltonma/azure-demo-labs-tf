variable "address_space_cloud_region" {
  description = "The CIDR block associated with the Azure region"
  type        = string
}

variable "address_space_on_prem" {
  description = "The CIDR block associated with the on-premises network"
  type        = string
}

variable "admin_username" {
  description = "The username of the administrator of the virtual machine"
  type        = string
}

variable "admin_password" {
  description = "The password of the administrator of the virtual machine"
  type        = string
  sensitive   = true
}

variable "asn_router" {
  description = "The ASN that will be assigned to the Quagga service"
  type        = string
  default    = 65001
}

variable "availability_zone" {
    description = "The availability zone to deploy the virtual machine"
    type        = string
    default     = null
}

variable "be_address_pool_priv_id" {
  description = "The ID of the backend address pool for the private NIC"
  type        = string
}

variable "be_address_pool_pub_id" {
  description = "The ID of the backend address pool for the public NIC"
  type        = string
}

variable "disk_data_storage_account_type" {
  description = "The storage account type for the data disk"
  type        = string
  default     =  "StandardSSD_LRS"
}

variable "disk_data_size_gb" {
  description = "The size of the data disk in GB"
  type        = number
  default     = 100
}

variable "disk_os_storage_account_type" {
  description = "The storage account type for the OS disk"
  type        = string
  default     =  "StandardSSD_LRS"
}

variable "disk_os_size_gb" {
  description = "The size of the OS disk in GB"
  type        = number
  default     = 30
}

variable "identities"{
  description = "The identities to assign to the virtual machine"
  type        = object({
    type = string
    identity_ids = list(string)
  })
  default = null
}

variable "image_reference" {
    description = "The reference to the image to use for the virtual machine"
    type        = object({
        publisher = string
        offer     = string
        sku       = string
        version   = string
    })
}

variable "ip_inner_gateway" {
  description = "The private IP address of the inner gateway"
  type        = string
}

variable "ip_outer_gateway" {
  description = "The private IP address of the outer gateway"
  type        = string
}

variable "law_resource_id" {
  description = "The resource id of the log analytics workspace"
  type        = string
}

variable "location" {
  description = "The location to deploy the virtual machine"
  type        = string
}

variable "location_code" {
  description = "The location code to append to the resource name"
  type = string
}

variable "nic_public_private_ip_address" {
  description = "The private IP address assigned to the NIC in the public subnet"
  type        = string
}

variable "nic_private_private_ip_address" {
  description = "The private IP address assigned to the NIC in the private subnet"
  type        = string
}

variable "purpose" {
  description = "The three character purpose code for the virtual machine"
  type        = string

}

variable "random_string" {
  description = "The random string to append to the virtual machine name"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy the virtual machine"
  type        = string
}

variable "subnet_id_private" {
  description = "The subnet the private NIC is deployed to"
  type        = string
}

variable "subnet_id_public" {
  description = "The subnet the public NIC is deployed to"
  type        = string
}

variable "tags" {
  description = "The tags to apply to the virtual machine"
  type        = map(string)
}

variable "vm_size" {
  description = "The size of the virtual machine"
  type        = string
  default     = "Standard_DC1s_v3"
}

