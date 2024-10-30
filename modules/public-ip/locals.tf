locals {
    # Standard naming convention for relevant resources
    public_ip_name = "pip"

    # Set properties of the public ip
    public_ip_sku = "Standard" 
    public_ip_allocation_method = "Static"
}