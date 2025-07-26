# Main Terraform configuration for RAG AI-Driven API and WebUI
# Azure Developer CLI compatible deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Data source for existing resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Data source for existing user-assigned managed identity
data "azurerm_user_assigned_identity" "existing" {
  name                = "rag-ai-api-identity-${var.resource_token}"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Common locals for resource naming and tagging
locals {
  resource_token = var.resource_token
  common_tags = {
    Application   = var.app_name
    Environment   = var.environment_name
    "azd-env-name" = var.environment_name
  }
}

# Generate resource names using azurecaf
resource "azurecaf_name" "app_service_plan" {
  name          = var.app_name
  resource_type = "azurerm_app_service_plan"
  suffixes      = [local.resource_token]
}

resource "azurecaf_name" "webui_app_service_plan" {
  name          = "rag-ai-webui"
  resource_type = "azurerm_app_service_plan"
  suffixes      = [local.resource_token]
}

resource "azurecaf_name" "app_service" {
  name          = var.app_name
  resource_type = "azurerm_app_service"
  suffixes      = [local.resource_token]
}

resource "azurecaf_name" "webui_app_service" {
  name          = "rag-ai-webui"
  resource_type = "azurerm_app_service"
  suffixes      = [local.resource_token]
}

resource "azurecaf_name" "application_insights" {
  name          = var.app_name
  resource_type = "azurerm_application_insights"
  suffixes      = ["insights", local.resource_token]
}

resource "azurecaf_name" "log_analytics_workspace" {
  name          = "rag-logs"
  resource_type = "azurerm_log_analytics_workspace"
  suffixes      = [local.resource_token]
}

resource "azurecaf_name" "openai_service" {
  name          = "rag-ai"
  resource_type = "azurerm_cognitive_account"
  suffixes      = [local.resource_token]
}

resource "azurecaf_name" "cosmos_db" {
  name          = "rag-cosmos"
  resource_type = "azurerm_cosmosdb_account"
  suffixes      = [local.resource_token]
}

resource "azurecaf_name" "search_service" {
  name          = "rag-search"
  resource_type = "azurerm_search_service"
  suffixes      = [local.resource_token]
}

resource "azurecaf_name" "storage_account" {
  name          = "ragdocs"
  resource_type = "azurerm_storage_account"
  suffixes      = [local.resource_token]
}

resource "azurecaf_name" "sql_server" {
  name          = "rag-sql"
  resource_type = "azurerm_mssql_server"
  suffixes      = [local.resource_token]
}

# App Service Plan for API
resource "azurerm_service_plan" "api" {
  name                = azurecaf_name.app_service_plan.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku

  tags = local.common_tags
}

# WebUI App Service Plan
resource "azurerm_service_plan" "webui" {
  name                = azurecaf_name.webui_app_service_plan.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku

  tags = local.common_tags
}

# Log Analytics Workspace for Application Insights
resource "azurerm_log_analytics_workspace" "main" {
  name                = azurecaf_name.log_analytics_workspace.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = azurecaf_name.application_insights.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  disable_ip_masking  = false

  tags = local.common_tags
}

# Azure OpenAI Service
resource "azurerm_cognitive_account" "openai" {
  name                = azurecaf_name.openai_service.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  kind                = "OpenAI"
  sku_name            = var.openai_sku
  custom_subdomain_name = azurecaf_name.openai_service.result

  public_network_access_enabled = true

  tags = local.common_tags
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  name                = azurecaf_name.cosmos_db.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  offer_type          = var.cosmos_db_offer_type
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = data.azurerm_resource_group.main.location
    failover_priority = 0
    zone_redundant    = false
  }

  dynamic "capabilities" {
    for_each = var.cosmos_db_serverless ? ["EnableServerless"] : []
    content {
      name = capabilities.value
    }
  }

  public_network_access_enabled    = true
  automatic_failover_enabled       = false
  multiple_write_locations_enabled = false

  tags = local.common_tags
}

# AI Search Service
resource "azurerm_search_service" "main" {
  name                = azurecaf_name.search_service.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = var.search_sku
  replica_count       = 1
  partition_count     = 1

  public_network_access_enabled = true
  local_authentication_enabled  = false

  tags = local.common_tags
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = azurecaf_name.storage_account.result
  location                 = data.azurerm_resource_group.main.location
  resource_group_name      = data.azurerm_resource_group.main.name
  account_tier             = "Standard"
  account_replication_type = var.storage_account_sku
  account_kind             = "StorageV2"
  access_tier              = var.storage_access_tier

  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = local.common_tags
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                = azurecaf_name.sql_server.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  version             = "12.0"

  public_network_access_enabled = true

  azuread_administrator {
    login_username              = data.azurerm_user_assigned_identity.existing.name
    object_id                   = data.azurerm_user_assigned_identity.existing.principal_id
    tenant_id                   = data.azurerm_user_assigned_identity.existing.tenant_id
    azuread_authentication_only = true
  }

  tags = local.common_tags
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name           = "rag_ai_bot_main"
  server_id      = azurerm_mssql_server.main.id
  collation      = var.sql_database_collation
  max_size_gb    = 2
  sku_name       = "Basic"
  zone_redundant = false
  storage_account_type = "Local"

  tags = local.common_tags
}

# SQL Server Firewall Rule
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Role assignments for Managed Identity access to services
# These are created after the App Service to avoid circular dependencies
resource "azurerm_role_assignment" "openai_user" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_linux_web_app.api.identity[0].principal_id

  depends_on = [azurerm_linux_web_app.api]
}

resource "azurerm_role_assignment" "cosmos_contributor" {
  scope                = azurerm_cosmosdb_account.main.id
  role_definition_name = "Cosmos DB Built-in Data Contributor"
  principal_id         = azurerm_linux_web_app.api.identity[0].principal_id

  depends_on = [azurerm_linux_web_app.api]
}

resource "azurerm_role_assignment" "search_contributor" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = azurerm_linux_web_app.api.identity[0].principal_id

  depends_on = [azurerm_linux_web_app.api]
}

resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.api.identity[0].principal_id

  depends_on = [azurerm_linux_web_app.api]
}

# API App Service
resource "azurerm_linux_web_app" "api" {
  name                = azurecaf_name.app_service.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.api.id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on              = true
    ftps_state            = "Disabled"
    minimum_tls_version   = "1.2"
    use_32_bit_worker     = false
    websockets_enabled    = false
    
    application_stack {
      python_version = var.python_version
    }

    dynamic "cors" {
      for_each = var.enable_cors ? [1] : []
      content {
        allowed_origins = [
          "https://rag-ai-webui-${local.resource_token}.azurewebsites.net",
          "http://localhost:3000",
          "http://localhost:5173",
          "http://localhost:8080"
        ]
        support_credentials = true
      }
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "8000"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"     = "true"
    "ENABLE_ORYX_BUILD"                   = "true"
    "ENVIRONMENT"                         = var.environment_name
    "PYTHON_ENABLE_GUNICORN_MULTIWORKERS" = "true"
    
    # Use Managed Identity instead of API keys for security
    "AZURE_CLIENT_ID"                     = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=azure-client-id)"
    "AZURE_OPENAI_ENDPOINT"               = azurerm_cognitive_account.openai.endpoint
    "COSMOS_DB_ENDPOINT"                  = azurerm_cosmosdb_account.main.endpoint
    "SEARCH_SERVICE_ENDPOINT"             = "https://${azurerm_search_service.main.name}.search.windows.net"
    "STORAGE_ACCOUNT_NAME"                = azurerm_storage_account.main.name
    "SQL_SERVER_NAME"                     = azurerm_mssql_server.main.fully_qualified_domain_name
    "SQL_DATABASE_NAME"                   = azurerm_mssql_database.main.name
    "SQL_CONNECTION_STRING"               = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.main.name};Authentication=Active Directory Managed Identity;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"
    
    # Application Insights
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key
  }

  tags = merge(local.common_tags, {
    "azd-service-name" = "api"
  })
}

# WebUI App Service
resource "azurerm_linux_web_app" "webui" {
  name                = azurecaf_name.webui_app_service.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.webui.id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on              = true
    ftps_state            = "Disabled"
    minimum_tls_version   = "1.2"
    use_32_bit_worker     = false
    websockets_enabled    = false
    
    application_stack {
      node_version = var.node_version
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "3000"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"     = "true"
    "ENABLE_ORYX_BUILD"                   = "true"
    "ENVIRONMENT"                         = var.environment_name
    
    # API URLs for different frameworks - use expected hostname pattern
    "REACT_APP_API_URL"     = "https://${azurecaf_name.app_service.result}.azurewebsites.net"
    "VITE_API_URL"          = "https://${azurecaf_name.app_service.result}.azurewebsites.net"
    "NEXT_PUBLIC_API_URL"   = "https://${azurecaf_name.app_service.result}.azurewebsites.net"
    "VUE_APP_API_URL"       = "https://${azurecaf_name.app_service.result}.azurewebsites.net"
    
    # Service endpoints (public endpoints only)
    "AZURE_OPENAI_ENDPOINT"    = azurerm_cognitive_account.openai.endpoint
    "SEARCH_SERVICE_ENDPOINT"  = "https://${azurerm_search_service.main.name}.search.windows.net"
    "STORAGE_ACCOUNT_ENDPOINT" = azurerm_storage_account.main.primary_blob_endpoint
  }

  tags = merge(local.common_tags, {
    "azd-service-name" = "webui"
  })
}

# Key Vault for storing secrets (recommended security practice)
resource "azurerm_key_vault" "main" {
  name                = "kv-${local.resource_token}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  tags = local.common_tags
}

# Key Vault access policy for API App Service (created separately to avoid circular dependency)
resource "azurerm_key_vault_access_policy" "api_access" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.api.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [azurerm_linux_web_app.api]
}

# Store the Managed Identity Client ID in Key Vault
resource "azurerm_key_vault_secret" "azure_client_id" {
  name         = "azure-client-id"
  value        = azurerm_linux_web_app.api.identity[0].principal_id
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault_access_policy.api_access,
    azurerm_linux_web_app.api
  ]
}
