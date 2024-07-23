locals {
  # Enable Private Endpoint network policies so NSGs are honored and UDRs
  # applied to other subnets accept the less specific route

  private_endpoint_network_policies = "Enabled"

  # Get first two characters of the location
  location_short = substr(var.location, 0, 2)

  # Configure standard naming convention for relevant resources
  vnet_name      = "vnet"
  flow_logs_name = "fl"
  dcr_association = "dcra"

  # Configure three character code for purpose of vnet
  vnet_purpose = "wl"

  # Configure some standard subnet names
  subnet_name_app  = "snet-app"
  subnet_name_data = "snet-data"
  subnet_name_svc  = "snet-svc"
  subnet_name_vint = "snet-vint"
  subnet_name_mgmt = "snet-mgmt"
  subnet_name_agw  = "snet-agw"
  subnet_name_apim = "snet-apim"
  subnet_name_tool = "snet-tool"

  # Enable flow log retention policy for 7 days
  flow_logs_enabled                  = true
  flow_logs_retention_policy_enabled = true
  flow_logs_retention_days           = 7

  # Enable traffic anlaytics for the network security group and set the interval to 60 minutes
  traffic_analytics_enabled             = true
  traffic_analytics_interval_in_minutes = 60

}