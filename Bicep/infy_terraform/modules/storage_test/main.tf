resource "azurerm_storage_account" "storage" {
  name                              = lower("${var.env}${var.storage_account_name}${random_id.unique.hex}")
  resource_group_name               = var.rg_name
  location                          = var.location
  account_tier                      = var.account_tier             #"Standard"
  account_replication_type          = var.account_replication_type #"LRS"
  account_kind                      = var.account_kind             #"StorageV2"
  public_network_access_enabled     = var.public_network_access_enabled
  https_traffic_only_enabled        = var.https_traffic_only_enabled
  shared_access_key_enabled         = var.shared_access_key_enabled
  min_tls_version                   = var.min_tls_version #"TLS1_1.2"
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

  dynamic "network_rules" {
    for_each = var.snet_id != "" ? [1] : []
    content {
      default_action             = "Deny"
      virtual_network_subnet_ids = [var.snet_id]
      #bypass                     = ["AzureServices"]
    }

  }


  blob_properties {
    versioning_enabled = var.enable_blob_versioning
    delete_retention_policy {
      days = var.delete_retention_days # Example: Keep deleted blobs for 7 days
    }
  }

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
      "Name"        = var.storage_account_name
    }
  )

  # network_rules {
  #   default_action             = "Deny"
  #   #ip_rules                   = ["100.0.0.1"]
  #   virtual_network_subnet_ids = [var.snet_id]
  # }
}

#This is moved to pe module
# resource "azurerm_private_endpoint" "pe" {
#   for_each = var.private_endpoint_enabled ? toset(var.subresource_names) : toset([])
#   name                = "${azurerm_storage_account.storage.name}-pe-${each.key}"
#   location            = var.location
#   resource_group_name = var.rg_name
#   subnet_id           = var.snet_id

#   private_service_connection {
#     name                           = "${azurerm_storage_account.storage.name}-psc-${each.key}"
#     private_connection_resource_id = azurerm_storage_account.storage.id
#     subresource_names              = [each.key]
#     is_manual_connection           = var.psc_is_manual_connection
#   }
#   private_dns_zone_group {
#     name                 = "default"
#     private_dns_zone_ids = [azurerm_private_dns_zone.example[0].id]
#   }
# }

#This is moved to pe module
# resource "azurerm_private_dns_zone" "example" {
#   count               = var.private_endpoint_enabled ? 1 : 0
#   name                = "privatelink.core.windows.net"
#   resource_group_name = var.rg_name
# }

#This is moved to pe module
# resource "azurerm_private_dns_zone_virtual_network_link" "example" {
#   count                 = var.private_endpoint_enabled ? 1 : 0
#   name                  = format("%s-%s-link", var.env, azurerm_storage_account.storage.name)
#   private_dns_zone_name = azurerm_private_dns_zone.example[0].name
#   virtual_network_id    = var.vnet_id
#   resource_group_name   = var.rg_name
# }


# resource "azurerm_private_dns_a_record" "dns_a_sta" {
#   count               = var.private_endpoint_enabled ? 1 : 0
#   name                = format("%s-%s-a_record", var.env, azurerm_storage_account.storage.name)
#   zone_name           = azurerm_private_dns_zone.example[0].name
#   resource_group_name = var.rg_name
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.pe[0].private_service_connection[0].private_ip_address]
#   #records             = [azurerm_private_endpoint.pe.private_service_connection.0.private_ip_address]
# }

module "storage_diag" {
  count                      = var.enable_storage_diagnostics ? 1 : 0
  source                     = "../../modules/diagnostic_setting_test"
  name                       = format("%s-%s-diagnostic", var.env, azurerm_storage_account.storage.name)
  target_resource_id         = "${azurerm_storage_account.storage.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_categories             = var.log_categories    #["StorageRead", "StorageWrite", "StorageDelete"]
  metric_categories          = var.metric_categories #["AllMetrics"]
}


resource "random_id" "unique" {
  byte_length = 4
}