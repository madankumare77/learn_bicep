resource "azurerm_service_plan" "plan" {
  for_each            = var.function_apps
  name                = "${var.env}-${each.key}-plan"
  location            = var.location
  resource_group_name = var.rg_name
  os_type             = each.value.os_type
  sku_name            = each.value.sku_name
  tags                = var.function_apps[each.key].tags
}

# module "storage" {
#   source               = "../storage"
#   for_each             = { for k, v in var.function_apps : k => v if v.storage_required }
#   storage_account_name = "${var.nemonic}-${each.value.storage_account_name}"
#   rg_name              = var.rg_name
#   location             = var.location
#   snet_id              = each.value.subnet_id
# }

module "storage_account" {
  source   = "../../modules/storage_test"
  for_each = { for k, v in var.function_apps : k => v if v.storage_required }

  storage_account_name = replace(each.key, "-", "")
  env                  = "dev"
  rg_name              = var.rg_name
  location             = var.location
  #account_tier         = each.value.account_tier
  #account_replication_type = each.value.account_replication_type
  #account_kind         = each.value.account_kind
  snet_id                  = each.value.subnet_id
  private_endpoint_enabled = each.value.private_endpoint_enabled
  #subresource_names    = each.value.subresource_names
  vnet_id = each.value.vnet_id
  tags    = var.function_apps[each.key].tags
}


resource "azurerm_windows_function_app" "windows" {
  for_each                                       = { for k, v in var.function_apps : k => v if v.os_type == "Windows" }
  name                                           = "${var.env}-${each.key}"
  location                                       = var.location
  resource_group_name                            = var.rg_name
  service_plan_id                                = azurerm_service_plan.plan[each.key].id
  public_network_access_enabled                  = each.value.public_network_access_enabled
  ftp_publish_basic_authentication_enabled       = true
  webdeploy_publish_basic_authentication_enabled = true
  storage_account_name                           = each.value.storage_required ? module.storage_account[each.key].storage_account_name : null
  storage_account_access_key                     = each.value.storage_required ? module.storage_account[each.key].primary_access_key : null
  site_config {
    application_stack {
      dotnet_version = each.value.runtime_stack
    }
    # Access restrictions to block public
    # ip_restriction {
    #   ip_address = "0.0.0.0/0"
    #   action     = "Deny"
    #   priority   = 100
    #   name       = "BlockAllPublic"
    # }
  }
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME   = "dotnet"
    WEBSITE_RUN_FROM_PACKAGE   = "1"
    storage_account_name       = each.value.storage_required ? module.storage_account[each.key].storage_account_name : null
    storage_account_access_key = each.value.storage_required ? module.storage_account[each.key].primary_access_key : null
  }
  virtual_network_subnet_id = each.value.subnet_id
  tags                      = var.function_apps[each.key].tags
}

resource "azurerm_linux_function_app" "linux" {
  for_each                      = { for k, v in var.function_apps : k => v if v.os_type == "Linux" }
  name                          = "${var.env}-${each.key}"
  location                      = var.location
  resource_group_name           = var.rg_name
  service_plan_id               = azurerm_service_plan.plan[each.key].id
  public_network_access_enabled = each.value.public_network_access_enabled
  storage_account_name          = each.value.storage_required ? module.storage_account[each.key].storage_account_name : null
  storage_account_access_key    = each.value.storage_required ? module.storage_account[each.key].primary_access_key : null
  site_config {
    application_stack {
      java_version = each.value.runtime_stack
    }
    # Access restrictions to block public
    # ip_restriction {
    #   ip_address = "0.0.0.0/0"
    #   action     = "Deny"
    #   priority   = 100
    #   name       = "BlockAllPublic"
    # }
  }
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME   = "java"
    WEBSITE_RUN_FROM_PACKAGE   = "1"
    storage_account_name       = each.value.storage_required ? module.storage_account[each.key].storage_account_name : null
    storage_account_access_key = each.value.storage_required ? module.storage_account[each.key].primary_access_key : null
  }
  virtual_network_subnet_id = each.value.subnet_id
  tags                      = var.function_apps[each.key].tags
}

# resource "azurerm_private_endpoint" "pe" {
#   for_each            = { for k, v in var.function_apps : k => v if v.private_endpoint_enabled }
#   name                = "${var.env}-${each.key}-pe"
#   location            = var.location
#   resource_group_name = var.rg_name
#   subnet_id           = var.function_apps[each.key].subnet_id

#   private_service_connection {
#     name                           = "${var.env}-${each.key}-psc"
#     private_connection_resource_id = each.value.os_type == "Windows" ? azurerm_windows_function_app.windows[each.key].id : azurerm_linux_function_app.linux[each.key].id
#     subresource_names              = ["functionapp"]
#     is_manual_connection           = false
#   }
# }
#azurerm_windows_function_app.windows[each.key].id != "" ? azurerm_windows_function_app.windows[each.key].id : azurerm_linux_function_app.linux[each.key].id


