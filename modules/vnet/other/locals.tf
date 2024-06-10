locals {
  # Enable Private Endpoint and Private Link Service Network Policies to
  # Network Security Groups are honored

  enable_private_endpoint_network_policies     = true
  enable_private_link_service_network_policies = true
}
