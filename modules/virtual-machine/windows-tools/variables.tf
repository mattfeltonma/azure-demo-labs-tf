variable "admin_username" {
  description = "The username of the administrator of the virtual machine"
  type        = string
}

variable "admin_password" {
  description = "The password of the administrator of the virtual machine"
  type        = string
  sensitive   = true
}

variable "availability_zone" {
    description = "The availability zone to deploy the virtual machine"
    type        = string
    default     = null
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
  default     = 128
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

variable "location" {
  description = "The location to deploy the virtual machine"
  type        = string
}

variable "private_ip_address" {
  description = "The private IP address of the virtual machine"
  type        = string
  default   = null
}

variable "private_ip_address_allocation" {
  description = "The private IP address allocation method"
  type        = string
  default     = "Dynamic"
}

variable "public_ip_address_id" {
  description = "The resource ID of the public IP address to associate with the virtual machine"
  type        = string
  default     = null
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

variable "subnet_id" {
  description = "The ID of the subnet to deploy the virtual machine"
  type        = string
}

variable "tags" {
  description = "The tags to apply to the virtual machine"
  type        = map(string)
}

variable "vm_size" {
  description = "The size of the virtual machine"
  type        = string
}

