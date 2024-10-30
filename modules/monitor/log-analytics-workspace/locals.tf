locals {
 # Configure standard naming convention for relevant resources
  nsg_name = "law"
  data_collection_rule_windows = "win"
  data_collection_rule_linux = "lin"

  # Log Analytics Workspace SKU
  log_analytics_sku = "PerGB2018"

}