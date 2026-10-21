# ============================================
# CREDENCIALES DE AZURE (Service Principal)
# ============================================
variable "subscription_id" {
  description = "ID de la suscripción de Azure"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "App ID del Service Principal"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Password del Service Principal"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Tenant ID (Directory ID)"
  type        = string
  sensitive   = true
}

# ============================================
# BASE DE DATOS SQL
# ============================================
variable "sql_admin_user" {
  description = "Usuario administrador del SQL Server"
  type        = string
  default     = "aiis"
}

variable "sql_admin_password" {
  description = "Contraseña del administrador del SQL Server"
  type        = string
  sensitive   = true
}

# ============================================
# NOMBRES DE SERVICIOS
# ============================================
variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
  default     = "gr-ucb-tarea2dwh-8736"
}

variable "location" {
  description = "Región principal"
  type        = string
  default     = "brazilsouth"
}

variable "storage_account_name" {
  description = "Nombre del Storage Account (solo minúsculas y números)"
  type        = string
  default     = "stotarea2dwh8736"
}

variable "storage_container_name" {
  description = "Nombre del contenedor de blobs"
  type        = string
  default     = "raw"
}

variable "sql_server_name" {
  description = "Nombre del SQL Server"
  type        = string
  default     = "sql-tarea2dwh-8736"
}

variable "sql_database_name" {
  description = "Nombre de la base de datos SQL"
  type        = string
  default     = "tarea2dwh_db"
}

variable "data_factory_name" {
  description = "Nombre del Data Factory"
  type        = string
  default     = "adf-tarea2dwh-us-8736"
}

variable "data_factory_location" {
  description = "Región del Data Factory"
  type        = string
  default     = "eastus"
}