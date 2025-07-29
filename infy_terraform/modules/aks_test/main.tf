resource "azurerm_kubernetes_cluster" "aks" {
  name                              = "${var.env}-${var.aks_name}"
  location                          = var.location
  resource_group_name               = var.rg_name
  dns_prefix                        = var.aks_name
  kubernetes_version                = var.kubernetes_version
  private_cluster_enabled           = var.private_cluster
  role_based_access_control_enabled = true
  local_account_disabled            = false #This should be set to true and add the AAD group to the role based access control
  # azure_active_directory_role_based_access_control {
  #   azure_rbac_enabled = true
  #   admin_group_object_ids = [azuread_group.aks_admins.object_id]
  # }

  default_node_pool {
    name = var.default_node_pool.name
    #node_count          = var.default_node_pool.node_count
    vm_size         = var.default_node_pool.vm_size
    os_disk_size_gb = var.default_node_pool.os_disk_size
    os_disk_type    = var.node_os_disk_type
    #mode                = var.mode
    zones               = var.default_node_pool.zones
    enable_auto_scaling = var.enable_auto_scale
    min_count           = var.default_node_pool.min_count
    max_count           = var.default_node_pool.max_count
    max_pods            = var.default_node_pool.max_pods
    vnet_subnet_id      = var.vnet_subnet_id
    #temporary_name_for_rotation = "tempnp1"
  }
  identity {
    type         = var.aks_identity_type #"UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  network_profile {
    network_plugin      = var.network_plugin
    load_balancer_sku   = var.load_balancer_sku
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    service_cidr        = var.aks_service_cidr   #"10.1.0.0/16"
    dns_service_ip      = var.aks_dns_service_ip #"10.1.0.10"
  }

  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = merge(
    var.tags,
    {
      "Environment" = var.env
      "Name"        = var.aks_name
    }
  )
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "${var.env}-${var.aks_name}-id"
  location            = var.location
  resource_group_name = var.rg_name
}


resource "azurerm_kubernetes_cluster_node_pool" "additional_node_pools" {
  for_each = var.additional_node_pools

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = each.value.vm_size
  mode                  = var.mode
  #node_count            = each.value.node_count
  os_disk_size_gb      = each.value.os_disk_size
  enable_auto_scaling  = var.enable_auto_scale
  min_count            = each.value.min_count
  max_count            = each.value.max_count
  max_pods             = each.value.max_pods
  vnet_subnet_id       = var.vnet_subnet_id
  zones                = each.value.zones
  orchestrator_version = var.kubernetes_version
  os_type              = each.value.aks_os_type
}

# resource "azuread_group" "aks_admins" {
#   display_name       = format("%s-aks-admins", var.env)
#   security_enabled   = true
#   assignable_to_role = true
#   description        = "Admin group for managing the AKS cluster"
# }

# resource "azurerm_role_assignment" "reader_role" {
#   scope                = azurerm_kubernetes_cluster.aks.id
#   role_definition_name = "Reader" # Assigning Reader role to the group
#   principal_id         = azuread_group.aks_admins.object_id
# }

module "aks_diag" {
  source                     = "../../modules/diagnostic_setting_test"
  name                       = "${var.env}-${var.aks_name}-diagnostic"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_categories             = ["kube-audit", "kube-apiserver", "kube-controller-manager", "kube-scheduler"]
  metric_categories          = ["AllMetrics"]
}

