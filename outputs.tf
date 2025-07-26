# Output values for RAG AI-Driven API and WebUI Terraform configuration

output "AZURE_WEBAPP_NAME" {
  description = "The name of the API App Service"
  value       = azurerm_linux_web_app.api.name
}

output "AZURE_WEBAPP_URL" {
  description = "The URL of the API App Service"
  value       = "https://${azurerm_linux_web_app.api.default_hostname}"
}

output "AZURE_WEBUI_NAME" {
  description = "The name of the WebUI App Service"
  value       = azurerm_linux_web_app.webui.name
}

output "AZURE_WEBUI_URL" {
  description = "The URL of the WebUI App Service"
  value       = "https://${azurerm_linux_web_app.webui.default_hostname}"
}

output "app_service_id" {
  description = "The resource ID of the API App Service"
  value       = azurerm_linux_web_app.api.id
}

output "webui_app_service_id" {
  description = "The resource ID of the WebUI App Service"
  value       = azurerm_linux_web_app.webui.id
}

output "app_service_principal_id" {
  description = "The principal ID of the API App Service managed identity"
  value       = azurerm_linux_web_app.api.identity[0].principal_id
}

output "webui_app_service_principal_id" {
  description = "The principal ID of the WebUI App Service managed identity"
  value       = azurerm_linux_web_app.webui.identity[0].principal_id
}

output "application_insights_instrumentation_key" {
  description = "Application Insights Instrumentation Key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights Connection String"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "openai_endpoint" {
  description = "Azure OpenAI Service endpoint"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_service_name" {
  description = "Azure OpenAI Service name"
  value       = azurerm_cognitive_account.openai.name
}

output "cosmos_db_endpoint" {
  description = "Cosmos DB account endpoint"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "cosmos_db_account_name" {
  description = "Cosmos DB account name"
  value       = azurerm_cosmosdb_account.main.name
}

output "search_service_endpoint" {
  description = "AI Search service endpoint"
  value       = "https://${azurerm_search_service.main.name}.search.windows.net"
}

output "search_service_name" {
  description = "AI Search service name"
  value       = azurerm_search_service.main.name
}

output "storage_account_name" {
  description = "Storage Account name"
  value       = azurerm_storage_account.main.name
}

output "storage_account_blob_endpoint" {
  description = "Storage Account blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "sql_server_name" {
  description = "SQL Server name"
  value       = azurerm_mssql_server.main.name
}

output "sql_database_name" {
  description = "SQL Database name"
  value       = azurerm_mssql_database.main.name
}

output "sql_server_fqdn" {
  description = "SQL Server FQDN"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}
