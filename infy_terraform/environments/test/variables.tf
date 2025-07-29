variable "env" {
  description = "The name of the environment"
  type        = string
  default     = "devinfy"
}

variable "location" {
  description = "The Azure region where the resources will be created"
  type        = string
  default     = "CentralIndia"
}

variable "enable_storage_account" {
  description = "Enable or disable Storage Account module"
  type        = bool
  default     = false
}
variable "enable_function_app" {
  description = "Enable or disable Function App module"
  type        = bool
  default     = false
}
variable "enable_aks" {
  description = "Enable or disable AKS module"
  type        = bool
  default     = false
}
variable "enable_kv" {
  description = "Enable or disable Key Vault module"
  type        = bool
  default     = false
}
variable "enable_postgresql_flex" {
  description = "Enable or disable PostgreSQL Flexible Server module"
  type        = bool
  default     = false
}
variable "enable_apim" {
  description = "Enable or disable API Management module"
  type        = bool
  default     = false
}
variable "enable_redis_cache" {
  description = "Enable or disable Redis Cache module"
  type        = bool
  default     = false
}
variable "enable_sqlmi" {
  description = "Enable or disable SQL Managed Instance module"
  type        = bool
  default     = false
}