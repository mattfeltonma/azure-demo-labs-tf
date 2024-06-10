locals {
    # Get first two characters of the location
    location_short = substr(var.location, 0, 2)

    # Standard naming convention for relevant resources
    public_ip_name = "pip"

    # Set properties of the public ip
    public_ip_sku = "Standard" 
    public_ip_allocation_method = "Static"
}