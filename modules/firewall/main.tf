## Create Azure Firewall Policy and Rule Collections
##
resource "azurerm_firewall_policy" "firewall_policy" {
  name                = "${local.fw_policy_name}${local.fw_purpose}${local.location_short}${var.random_string}"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku = var.sku_tier

  dns {
    proxy_enabled = true
    servers       = var.dns_servers
  }

  insights {
    enabled                            = true
    default_log_analytics_workspace_id = var.law_resource_id
    retention_in_days                  = 30

    log_analytics_workspace {
      id                = var.law_resource_id
      firewall_location = var.law_workspace_region
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "rule_collection_group_dnat" {
  depends_on = [
    azurerm_firewall_policy.firewall_policy
  ]

  name               = "DefaultDNATRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = 100

}

resource "azurerm_firewall_policy_rule_collection_group" "rule_collection_group_network" {
  depends_on = [
    azurerm_firewall_policy.firewall_policy
  ]
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = 200
  network_rule_collection {
    name     = "AllowWindowsVmRequired"
    action   = "Allow"
    priority = 100
    rule {
      name        = "AllowKmsActivation"
      description = "Allows activation of Windows VMs with Azure KMS Service"
      protocols = [
        "TCP"
      ]
      source_addresses = [
        var.address_space_azure
      ]
      destination_fqdns = [
        "kms.core.windows.net",
        "azkms.core.windows.net"
      ]
      destination_ports = [
        "1688"
      ]
    }
    rule {
      name        = "AllowNtp"
      description = "Allow machines to communicate with NTP servers"
      protocols = [
        "TCP",
        "UDP"
      ]
      source_addresses = [
        var.address_space_azure
      ]
      destination_fqdns = [
        "time.windows.com"
      ]
      destination_ports = [
        "123"
      ]
    }
  }
  network_rule_collection {
    name     = "AllowLinuxVmRequired"
    action   = "Allow"
    priority = 200
    rule {
      name        = "AllowNtp"
      description = "Allow machines to communicate with NTP servers"
      protocols = [
        "TCP",
        "UDP"
      ]
      source_addresses = [
        var.address_space_azure
      ]
      destination_fqdns = [
        "ntp.ubuntu.com"
      ]
      destination_ports = [
        "123"
      ]
    }
  }
  network_rule_collection {
    name     = "AllowOnPremisesRemoteAccess"
    action   = "Allow"
    priority = 300
    rule {
      name        = "AllowOnPremisesRemoteAccess"
      description = "Allow machines on-premises to establish remote connections over RDP and SSH"
      protocols = [
        "TCP"
      ]
      source_addresses = [
        var.address_space_onpremises
      ]
      destination_addresses = [
        var.address_space_azure
      ]
      destination_ports = [
        "22",
        "3389"
      ]
    }
  }
  network_rule_collection {
    name     = "AllowDns"
    action   = "Allow"
    priority = 400
    rule {
      name        = "AllowDnsInAzure"
      description = "Allow machines in Azure to communicate with DNS servers"
      protocols = [
        "TCP",
        "UDP"
      ]
      source_addresses = [
        var.address_space_onpremises,
        var.address_space_azure
      ]
      destination_addresses = [
        var.dns_cidr
      ]
      destination_ports = [
        "22",
        "3389"
      ]
    }
  }
  network_rule_collection {
    name     = "AllowAzureToAzure"
    action   = "Allow"
    priority = 500
    rule {
      name        = "AllowAzureToAzure"
      description = "Allow Azure resources to communicate with each other"
      protocols = [
        "TCP",
        "UDP"
      ]
      source_addresses = [
        var.address_space_azure
      ]
      destination_addresses = [
        var.address_space_azure
      ]
      destination_ports = [
        "*"
      ]
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "rule_collection_group_application" {
  depends_on = [
    azurerm_firewall_policy.firewall_policy
  ]
  name               = "DefaultApplicationkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = 300
  application_rule_collection {
    name     = "AllowAzureToInternetTraffic"
    action   = "Allow"
    priority = 100
    rule {
      name        = "AllowAzureResourcesToInternet"
      description = "Allows Azures resources to contact any HTTP or HTTPS endpoint"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = [
        var.address_space_azure
      ]
      destination_fqdns = [
        "*"
      ]
    }
  }
  application_rule_collection {
    name     = "AllowOnPremisesToAzure"
    action   = "Allow"
    priority = 200
    rule {
      name        = "AllowOnPremisesToAzure"
      description = "Allows Azures resources to contact any HTTP or HTTPS endpoint"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = [
        var.address_space_onpremises
      ]
      destination_fqdns = [
        "*"
      ]
    }
  }
}

## Create Public IP, Azure Firewall instance, and diagnostic settings
##
module "public-ip" {
  source              = "../../modules/public-ip"
  random_string       = var.random_string
  purpose             = "afw"
  location            = var.location
  resource_group_name = var.resource_group_name

  law_resource_id = var.law_resource_id

  tags = var.tags
}

resource "azurerm_firewall" "firewall" {

  depends_on = [
    azurerm_firewall_policy.firewall_policy,
    module.public-ip
  ]

  name                = "${local.fw_name}${local.fw_purpose}${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku_name           = "AZFW_VNet"
  sku_tier           = var.sku_tier
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id

  ip_configuration {
    name                 = "fwipconfig"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = module.public-ip.id
  }

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag-base" {
  depends_on = [
    azurerm_firewall.firewall
  ]

  name                           = "diag-base"
  target_resource_id             = azurerm_firewall.firewall.id
  log_analytics_workspace_id     = var.law_resource_id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "AZFWNetworkRule"
  }
  enabled_log {
    category = "AZFWApplicationRule"
  }
  enabled_log {
    category = "AZFWNatRule"
  }
  enabled_log {
    category = "AZFWThreatIntel"
  }
  enabled_log {
    category = "AZFWIdpsSignature"
  }
  enabled_log {
    category = "AZFWDnsQuery"
  }
  enabled_log {
    category = "AZFWFqdnResolveFailure"
  }
  enabled_log {
    category = "AZFWApplicationRuleAggregation"
  }
  enabled_log {
    category = "AZFWNetworkRuleAggregation"
  }
  enabled_log {
    category = "AZFWNatRuleAggregation"
  }
  metric {
    category = "AllMetrics"
  }
}
