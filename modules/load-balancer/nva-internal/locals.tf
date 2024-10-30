locals {
    # Standard naming convention for relevant resources
    lb_name = "lb"
    lb_fe_config_name = "lbfe"
    lb_pool_name = "lbpoolbeint"
    lb_probe_name = "lbprobebeint"
    lb_rule_name = "lbrulebeint"

    # Set product-specific settings
    sku = "Standard"
    sku_tier = "Regional"
    allocation = "Static"

    # Set implementation specific settings
    probe_port = 22
    probe_protocol = "Tcp"
    probe_interval = 5
    probe_number_of_probes = 2

    rule_frontend_port = 0
    rule_backend_port = 0
    rule_protocol = "All"
    rule_enable_floating_ip = true
    rule_idle_timeout_in_minutes = 4
    rule_load_distribution = "Default"
    rule_disable_outbound_snat = true
}