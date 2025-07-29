resource "azurerm_postgresql_flexible_server" "this" {
  name                   = format("%s-%s", var.env, var.psql_server_name)
  resource_group_name    = var.rg_name
  location               = var.location #Multi-Zone HA is not supported in Centarl India region so we default to SameZone
  sku_name               = var.sku_name #az postgres flexible-server list-skus --location centralindia
  storage_mb             = var.storage_mb
  version                = var.psql_version
  administrator_login    = var.psql_administrator_login
  administrator_password = var.psql_administrator_password #random_password.pass.result
  zone                   = var.zone

  high_availability {
    mode                      = var.high_availability_mode
    standby_availability_zone = var.standby_zone
  }

  authentication {
    #password_auth_enabled         = var.password_auth_enabled
    active_directory_auth_enabled = var.active_directory_auth_enabled
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }


  backup_retention_days         = var.backup_retention_days
  public_network_access_enabled = var.public_network_access_enabled

  delegated_subnet_id = var.subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.example.id #required when setting a delegated_subnet_id

  depends_on = [var.subnet_id]

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
      "Name"        = var.psql_server_name
    }
  )
}

resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = format("%s-%s-link", var.env, var.psql_server_name)
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.rg_name
  depends_on            = [var.vnet_id]
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  count     = var.db_name != "" ? 1 : 0
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = var.charset
  collation = var.collation
}

module "postgres_diag" {
  source                     = "../../modules/diagnostic_setting_test"
  name                       = format("%s-%s-diagnostic", var.env, var.psql_server_name)
  target_resource_id         = azurerm_postgresql_flexible_server.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_categories             = var.log_categories    #["PostgreSQLLogs"]
  metric_categories          = var.metric_categories #["AllMetrics"]
}

data "azurerm_client_config" "current" {}


