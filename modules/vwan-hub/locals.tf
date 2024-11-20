locals {
    # Naming conventions
    vwan_hub_name = "vwanh"
    virtual_network_gateway_name = "vng"
    default_route_table_name = "defaultRouteTable"
    default_route_table_labels = [
        "default"
    ]

    # Virtual WAN Hub Configuration
    virtual_router_auto_scale_min_capacity = 2
    sku = "Standard"
}