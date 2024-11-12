locals {
    # Standard naming convention for relevant resources
    lb_name = "lb"
    lb_fe_config_name = "lbfe"
    lb_pool_name = "lbpoolbeext"
    lb_probe_name = "lbprobebeext"

    # Set product-specific settings
    sku = "Standard"
    sku_tier = "Regional"
    allocation = "Static"

    # Set implementation specific settings
    probe_port = 2222
    probe_protocol = "Tcp"
    probe_interval = 5
    probe_number_of_probes = 2
}