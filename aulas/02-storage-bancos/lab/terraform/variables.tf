variable "location" {
  description = "Região do Azure onde os recursos serão provisionados"
  type        = string
  default     = "eastus2"
}

variable "sql_admin_password" {
  description = "Senha do admin do Azure SQL Server. Gere uma forte com: openssl rand -base64 24"
  type        = string
  sensitive   = true
}
