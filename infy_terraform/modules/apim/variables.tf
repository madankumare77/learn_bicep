variable "apim_name" {
  description = "Name of the API Management instance"
  type        = string
  default     = "nonprod-infy"
}
variable "sku_name" {
  description = "The SKU name of the API Management instance"
  type        = string
  default     = "Developer_1"
}
variable "location" {
  description = "The Azure region where the API Management instance will be deployed"
  type        = string
  default     = "East US"
}
variable "rg_name" {
  description = "The name of the resource group where the API Management instance will be deployed"
  type        = string
}
variable "subnet_id" {
  description = "The ID of the subnet where the API Management instance will be deployed"
  type        = string

}
variable "environment" {
  description = "The environment for which the API Management instance is being created (e.g., dev, prod)"
  type        = string
}
variable "publisher_name" {
  description = "The name of the publisher of the API Management instance"
  type        = string
  default     = ""
}
variable "publisher_email" {
  description = "The email of the publisher of the API Management instance"
  type        = string
  default     = ""

}
variable "tags" {
  description = "A map of tags to assign to the API Management instance"
  type        = map(string)
  default     = {}
}