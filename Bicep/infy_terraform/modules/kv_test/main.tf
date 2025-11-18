variable "name" {
  description = "The name prefix for the Key Vault"
  type        = string

}
variable "rg_name" {
  description = "The name of the resource group where the Key Vault will be created"
  type        = string

}
variable "location" {
  description = "The Azure region where the resources will be created"
  type        = string
}

variable "env" {
  description = "The name of the environment"
  type        = string
}

variable "purge_protection_enabled" {
  description = "Enable purge protection for the Key Vault"
  type        = bool
  default     = true

}
variable "soft_delete_retention_days" {
  description = "The number of days to retain soft-deleted Key Vaults"
  type        = number
  default     = 7
}
variable "sku_name" {
  description = "The SKU name for the Key Vault"
  type        = string
  default     = "standard"
}
variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization for the Key Vault"
  type        = bool
  default     = true
}
variable "public_network_access_enabled" {
  description = "Enable public network access for the Key Vault"
  type        = bool
  default     = false
}
variable "enabled_for_deployment" {
  description = "Enable the Key Vault for deployment"
  type        = bool
  default     = true
}
variable "enanble_for_disk_encryption" {
  description = "Enable the Key Vault for disk encryption"
  type        = bool
  default     = true
}
variable "enabled_for_template_deployment" {
  description = "Enable the Key Vault for template deployment"
  type        = bool
  default     = true
}
variable "subnet_id" {
  description = "The ID of the subnet for the Key Vault private endpoint"
  type        = string
  default     = "" # Optional, can be set to an empty string if not used
}
variable "private_endpoint_enabled" {
  description = "Enable private endpoint for the Key Vault"
  type        = bool
  default     = false
}
variable "vnet_id" {
  description = "The ID of the virtual network to which the Key Vault will be associated"
  type        = string
  default     = "" # Optional, can be set to an empty string if not used  
}
variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace for diagnostic settings"
  type        = string
  default     = "" # Optional, can be set to an empty string if not used  
}
variable "log_categories" {
  description = "List of log categories for diagnostic settings"
  type        = list(string)
  default     = ["AuditEvent"] # Default categories, can be customized  
}
variable "metric_categories" {
  description = "List of metric categories for diagnostic settings"
  type        = list(string)
  default     = ["AllMetrics"] # Default categories, can be customized    
}
variable "tags" {
  description = "Tags to apply to the Key Vault"
  type        = map(string)
  default     = {}
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                          = format("%s-%s-%s", var.env, var.name, "${random_id.unique.hex}")
  location                      = var.location
  resource_group_name           = var.rg_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.sku_name
  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = var.soft_delete_retention_days
  enable_rbac_authorization     = var.enable_rbac_authorization
  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = var.subnet_id != "" ? [var.subnet_id] : []
  }

  # Access settings for deployment integration
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enanble_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
      "Name"        = var.name
    }
  )
}

resource "azurerm_private_endpoint" "pe" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = format("%s-%s-pe", var.env, var.name)
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = format("%s-%s-psc", var.env, var.name)
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["Vault"]
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.example[0].id]
  }
}

resource "azurerm_private_dns_zone" "example" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  count                 = var.private_endpoint_enabled ? 1 : 0
  name                  = format("%s-%s-link", var.env, azurerm_key_vault.kv.name)
  private_dns_zone_name = azurerm_private_dns_zone.example[0].name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.rg_name
}


resource "azurerm_private_dns_a_record" "dns_a_sta" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = format("%s-%s-a_record", var.env, azurerm_key_vault.kv.name)
  zone_name           = azurerm_private_dns_zone.example[0].name
  resource_group_name = var.rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe[0].private_service_connection[0].private_ip_address]
  #records             = [azurerm_private_endpoint.pe.private_service_connection.0.private_ip_address]
}

variable "enable_kv_diagnostics" {
  description = "Enable diagnostic settings for the Key Vault"
  type        = bool
  default     = true
}
module "kv_diag" {
  count                      = var.enable_kv_diagnostics ? 1 : 0
  source                     = "../../modules/diagnostic_setting_test"
  name                       = format("%s-%s-diagnostic", var.env, azurerm_key_vault.kv.name)
  target_resource_id         = azurerm_key_vault.kv.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_categories             = var.log_categories
  metric_categories          = var.metric_categories
}

# resource "azuread_application" "example" {
#   display_name = format("%s-%s-kv-app", var.env, var.name)
#   owners       = [data.azuread_client_config.current.object_id]
# }

# resource "azuread_service_principal" "example" {
#   client_id                    = azuread_application.example.client_id
#   app_role_assignment_required = false
#   owners                       = [data.azuread_client_config.current.object_id]
# }

# resource "azurerm_role_assignment" "spn_kv_reader" {
#   scope                = azurerm_key_vault.kv.id
#   role_definition_name = "Key Vault Reader"
#   principal_id         = azuread_service_principal.example.id
# }


data "azuread_client_config" "current" {}
# Required to get the tenant ID for the Key Vault
data "azurerm_client_config" "current" {}

resource "random_id" "unique" {
  byte_length = 4
}
