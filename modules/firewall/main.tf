## Create IP Groups
##
resource "azurerm_ip_group" "on_prem" {
  name                = "${local.ip_group_name}onprem${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name

  cidrs = [
    var.address_space_onpremises
  ]

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_ip_group" "azure" {
  name                = "${local.ip_group_name}azure${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name

  cidrs = [
    var.address_space_azure
  ]

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_ip_group" "rfc1918" {
  name                = "${local.ip_group_name}rfc1918${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name

  cidrs = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_ip_group" "apim" {
  name                = "${local.ip_group_name}apim${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name

  cidrs = [
    var.address_space_apim
  ]

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}
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

resource "azurerm_firewall_policy_rule_collection_group" "rule_collection_group_enterprise" {
  depends_on = [
    azurerm_firewall_policy.firewall_policy,
    azurerm_ip_group.azure,
    azurerm_ip_group.on_prem,
    azurerm_ip_group.rfc1918
  ]
  name               = "MyEnterpriseRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = 400
  network_rule_collection {
    name     = "AllowWindowsVmRequired"
    action   = "Allow"
    priority = 1000
    rule {
      name        = "AllowKmsActivation"
      description = "Allows activation of Windows VMs with Azure KMS Service"
      protocols = [
        "TCP"
      ]
      source_ip_groups = [
        azurerm_ip_group.azure.id
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
      source_ip_groups = [
        azurerm_ip_group.azure.id
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
    priority = 1100
    rule {
      name        = "AllowNtp"
      description = "Allow machines to communicate with NTP servers"
      protocols = [
        "TCP",
        "UDP"
      ]
      source_ip_groups = [
        azurerm_ip_group.azure.id
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
    priority = 1200
    rule {
      name        = "AllowOnPremisesRemoteAccess"
      description = "Allow machines on-premises to establish remote connections over RDP and SSH"
      protocols = [
        "TCP"
      ]
      source_ip_groups = [
        azurerm_ip_group.on_prem.id
      ]
      destination_ip_groups = [
        azurerm_ip_group.azure.id
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
    priority = 1300
    rule {
      name        = "AllowDnsInAzure"
      description = "Allow machines in Azure to communicate with DNS servers"
      protocols = [
        "TCP",
        "UDP"
      ]
      source_ip_groups = [
        azurerm_ip_group.azure.id,
        azurerm_ip_group.on_prem.id
      ]
      destination_addresses = [
        var.dns_cidr
      ]
      destination_ports = [
        "53"
      ]
    }
  }
  network_rule_collection {
    name     = "AllowAzureToAzure"
    action   = "Allow"
    priority = 1400
    rule {
      name        = "AllowAzureToAzure"
      description = "Allow Azure resources to communicate with each other"
      protocols = [
        "TCP",
        "UDP"
      ]
      source_ip_groups = [
        azurerm_ip_group.azure.id
      ]
      destination_ip_groups = [
        azurerm_ip_group.azure.id
      ]
      destination_ports = [
        "*"
      ]
    }
  }
  application_rule_collection {
    name     = "AllowAzureToInternetTraffic"
    action   = "Allow"
    priority = 2000
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
      source_ip_groups = [
        azurerm_ip_group.azure.id
      ]
      destination_fqdns = [
        "*"
      ]
    }
  }
  application_rule_collection {
    name     = "AllowOnPremisesToAzure"
    action   = "Allow"
    priority = 2100
    rule {
      name        = "AllowWebTrafficOnPremisesToAzure"
      description = "Allows Azures resources to contact any HTTP or HTTPS endpoint"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [
        azurerm_ip_group.on_prem.id
      ]
      destination_fqdns = [
        "*"
      ]
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "rule_collection_group_workload" {
  depends_on = [
    azurerm_firewall_policy.firewall_policy,
    azurerm_ip_group.azure,
    azurerm_ip_group.on_prem,
    azurerm_ip_group.rfc1918
  ]
  name               = "MyWorkloadRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = 600

  network_rule_collection {
    name     = "AllowInternalApimNetworkRules"
    action   = "Allow"
    priority = 1500
    rule {
      name        = "AllowAzureMonitor"
      description = "Allow APIM instance to communicate with Azure Monitor"
      protocols = [
        "TCP"
      ]
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_addresses = [
        "AzureMonitor"
      ]
      destination_ports = [
        "1886",
        "443",
        "12000"
      ]
    }
    rule {
      name        = "AllowAzureStorage"
      description = "Allow APIM instance to communicate with Azure Storage"
      protocols = [
        "TCP"
      ]
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_addresses = [
        "Storage"
      ]
      destination_ports = [
        "443",
        "445"
      ]
    }
    rule {
      name        = "AllowEventHub"
      description = "Allow APIM instance to communicate with Azure Event Hub"
      protocols = [
        "TCP"
      ]
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_addresses = [
        "EventHub"
      ]
      destination_ports = [
        "443",
        "5671-5672"
      ]
    }
    rule {
      name        = "AllowKeyVault"
      description = "Allow APIM instance to communicate with Azure Key Vault"
      protocols = [
        "TCP"
      ]
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_addresses = [
        "AzureKeyVault"
      ]
      destination_ports = [
        "443"
      ]
    }
    rule {
      name        = "AllowSql"
      description = "Allow APIM instance to communicate with Azure SQL"
      protocols = [
        "TCP"
      ]
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_addresses = [
        "Sql"
      ]
      destination_ports = [
        "1433"
      ]
    }
    rule {
      name        = "AllowNtp"
      description = "Allow APIM instance to communicate with NTP servers"
      protocols = [
        "UDP"
      ]
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_addresses = [
        "*"
      ]
      destination_ports = [
        "123"
      ]
    }
    rule {
      name        = "AllowDns"
      description = "Allow APIM instance to communicate with DNS servers"
      protocols = [
        "UDP",
        "TCP"
      ]
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_addresses = [
        var.dns_cidr
      ]
      destination_ports = [
        "53"
      ]
    }
    rule {
      name        = "AllowAzureKmsServers"
      description = "Allow Windows machines to activate with Azure KMS Servers"
      protocols = [
        "TCP"
      ]
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_addresses = [
        "AzurePlatformLKM"
      ]
      destination_ports = [
        "1688"
      ]
    }
    rule {
      name        = "AllowEntraID"
      description = "Allow traffic to Entra ID"
      protocols = [
        "TCP"
      ]
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_addresses = [
        "AzureActiveDirectory"
      ]
      destination_ports = [
        "443",
        "80"
      ]
    }
  }
  application_rule_collection {
    name     = "AllowInternalApimAppRules"
    action   = "Allow"
    priority = 1200
    rule {
      name        = "AllowCrlLookups"
      description = "Allows network flows to support CRL checks for APIM instance hosts"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_fqdns = [
        "ocsp.msocsp.com",
        "crl.microsoft.com",
        "mscrl.microsoft.com",
        "ocsp.digicert.com",
        "oneocsp.microsoft.com",
        "issuer.pki.azure.com"
      ]
    }
    rule {
      name        = "AllowPortalDiagnostics"
      description = "Allows network flows to support Azure Portal Diagnostics"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_fqdns = [
        "dc.services.visualstudio.com"
      ]
    }
    rule {
      name        = "AllowMicrosoftDiagnostics"
      description = "Allows network flows to support Microsoft Diagnostics on APIM instance hosts"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_fqdns = [
        "azurewatsonanalysis-prod.core.windows.net",
        "shavamanifestazurecdnprod1.azureedge.net",
        "shavamanifestcdnprod1.azureedge.net",
        "settings-win.data.microsoft.com",
        "v10.events.data.microsoft.com"
      ]
    }
    rule {
      name        = "AllowWindowsUpdate"
      description = "Allows network flows to support Microsoft Updates on APIM instance hosts"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_fqdns = [
        "*.update.microsoft.com",
        "*.ctldl.windowsupdate.com",
        "ctldl.windowsupdate.com",
        "download.windowsupdate.com",
        "fe3.delivery.mp.microsoft.com",
        "go.microsoft.com",
        "msedge.api.cdp.microsoft.com"
      ]
    }
    rule {
      name        = "AllowMicrosoftDefender"
      description = "Allows network flows to support Microsoft Defender on APIM instance hosts"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_fqdns = [
        "wdcp.microsoft.com",
        "wdcpalt.microsoft.com"
      ]
    }
    rule {
      name        = "AllowOtherFlow"
      description = "Allows network flows to support other flows to bootstrap APIM instance hosts"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [
        azurerm_ip_group.apim.id
      ]
      destination_fqdns = [
        "config.edge.skype.com",
        "azureprofiler.trafficmanager.net",
        "clientconfig.passport.net"
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
