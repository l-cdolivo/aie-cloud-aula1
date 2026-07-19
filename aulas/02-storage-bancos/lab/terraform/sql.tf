# SQL Server (lógico)
resource "azurerm_mssql_server" "qc" {
  name                         = "sql-qc-${random_string.sufixo.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladminqc"
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
  tags                         = local.tags
}

# Permite serviços Azure conectarem (necessário para a Function da Aula 3)
resource "azurerm_mssql_firewall_rule" "azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.qc.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Libera o IP atual do Cloud Shell para conexão direta via Python
data "http" "meu_ip" {
  url = "https://api.ipify.org"
}

resource "azurerm_mssql_firewall_rule" "cloud_shell" {
  name             = "CloudShellAccess"
  server_id        = azurerm_mssql_server.qc.id
  start_ip_address = chomp(data.http.meu_ip.response_body)
  end_ip_address   = chomp(data.http.meu_ip.response_body)
}

# Azure SQL Database FREE OFFER
# 100k vCore-seconds/mês + 32GB grátis. Auto-pausa quando inativo.
resource "azurerm_mssql_database" "qc" {
  name                           = "sqldb-qc"
  server_id                      = azurerm_mssql_server.qc.id
  sku_name                    = "GP_S_Gen5_2"
  auto_pause_delay_in_minutes = 60
  min_capacity                   = 0.5
  max_size_gb                    = 32
  tags                           = local.tags
}
