# ─────────────────────────────────────────────────────────────────────────────
# N3 3.1 — Azure OpenAI com text-embedding-3-small e gpt-4o-mini
# Responsável: Pessoa 2 (Luciana) — embeddings + dependência do N3 3.3 (Lucas)
#
# ATENÇÃO: Azure OpenAI não está disponível em Brazil South.
# Usar eastus2 ou swedencentral.
# ─────────────────────────────────────────────────────────────────────────────

# Região separada para o OpenAI (não herda var.location que é brazilsouth)
variable "openai_location" {
  description = "Região onde o Azure OpenAI será provisionado (eastus2 ou swedencentral)"
  type        = string
  default     = "eastus2"
}

# ── Conta Azure OpenAI ────────────────────────────────────────────────────────
resource "azurerm_cognitive_account" "openai" {
  name                = "openai-qc-${random_string.sufixo.result}"
  location            = var.openai_location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "OpenAI"
  sku_name            = "S0"

  # custom_subdomain obrigatório para autenticação via Managed Identity (Ex. 1.3)
  custom_subdomain_name = "openai-qc-${random_string.sufixo.result}"

  tags = local.tags
}

# ── Deployment: text-embedding-3-small (N3 3.1 — Pessoa 2) ───────────────────
resource "azurerm_cognitive_deployment" "embeddings" {
  name                 = "text-embedding-3-small"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "text-embedding-3-small"
    version = "1"
  }

  sku {
    name     = "Standard"
    capacity = 30  # 30k tokens/min
  }
}

# ── Deployment: gpt-4o-mini (N3 3.3 — Pessoa 3 / Lucas) ──────────────────────
resource "azurerm_cognitive_deployment" "chat" {
  name                 = "gpt-4o-mini"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o-mini"
    version = "2024-07-18"
  }

  sku {
    name     = "Standard"
    capacity = 20  # 20k tokens/min
  }

  depends_on = [azurerm_cognitive_deployment.embeddings]
}

# ── Role: Function MI pode chamar o Azure OpenAI sem chave ───────────────────
# Necessário para a rota /sumarizar-reviews-produto (N3 3.3) e para o script
# de embeddings rodado com a identidade do Cloud Shell (N3 3.1).
resource "azurerm_role_assignment" "fn_openai_user" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_linux_function_app.fn.identity[0].principal_id
}

# Role para o usuário autenticado no Cloud Shell rodar o script N3 3.1 localmente
resource "azurerm_role_assignment" "shell_openai_user" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ── App Settings adicionais na Function (complementa function.tf) ─────────────
# Adicione estes pares ao bloco app_settings do azurerm_linux_function_app.fn
# em function.tf (não duplicar o resource — só o mapa de settings):
#
#   "AZURE_OPENAI_ENDPOINT"    = azurerm_cognitive_account.openai.endpoint
#   "AZURE_OPENAI_DEPLOYMENT"  = azurerm_cognitive_deployment.chat.name
#   "COSMOS_DB"                = "qc-db"
#   "COSMOS_CONTAINER_REVIEWS" = "reviews"

# ── Outputs ───────────────────────────────────────────────────────────────────
output "openai_endpoint" {
  description = "Endpoint do Azure OpenAI — use como AZURE_OPENAI_ENDPOINT no script 3.1"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_embedding_deployment" {
  description = "Nome do deployment de embeddings"
  value       = azurerm_cognitive_deployment.embeddings.name
}

output "openai_chat_deployment" {
  description = "Nome do deployment de chat (gpt-4o-mini)"
  value       = azurerm_cognitive_deployment.chat.name
}
