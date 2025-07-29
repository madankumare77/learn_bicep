resource "azurerm_private_endpoint" "this" {
  name                = "${var.name}-${var.subresource_names[0]}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-${var.subresource_names[0]}-psc"
    private_connection_resource_id = var.private_connection_resource_id
    subresource_names              = var.subresource_names
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.dns_zone != "" ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [azurerm_private_dns_zone.example[0].id]
    }
  }
}

resource "azurerm_private_dns_zone" "example" {
  count               = var.dns_zone != "" ? 1 : 0
  name                = var.dns_zone
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  count                 = var.dns_zone != "" ? 1 : 0
  name                  = "${var.name}-${var.subresource_names[0]}-vnetlink"
  private_dns_zone_name = azurerm_private_dns_zone.example[0].name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
}

variable "name" {}
variable "location" {}
variable "resource_group_name" {}
variable "subnet_id" {}
variable "private_connection_resource_id" {}
variable "subresource_names" {
  type = list(string)
}
variable "dns_zone" {
  type    = string
  default = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "vnet_id" {
  type    = string
  default = ""
}
