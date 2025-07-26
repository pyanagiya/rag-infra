# Main Terraform template for TEIOS AI-Driven API and WebUI
# Azure Developer CLI compatible deployment

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Data source for existing User-Assigned Managed Identity
data "azurerm_user_assigned_identity" "existing" {
  name                = "teios-ai-api-identity-${var.resource_token}"
  resource_group_name = data.azurerm_resource_group.current.name
}

# Data source for current resource group
data "azurerm_resource_group" "current" {
  name = var.resource_group_name
}

# Resource naming convention using azurecaf
resource "azurecaf_name" "app_service_plan" {
  name          = var.app_name
  resource_type = "azurerm_app_service_plan"
  prefixes      = ["plan"]
  suffixes      = [var.resource_token]
  clean_input   = true
}

resource "azurecaf_name" "webui_app_service_plan" {
  name          = "teios-ai-webui"
  resource_type = "azurerm_app_service_plan"
  prefixes      = ["plan"]
  suffixes      = [var.resource_token]
  clean_input   = true
}

resource "azurecaf_name" "app_service" {
  name          = var.app_name
  resource_type = "azurerm_app_service"
  suffixes      = [var.resource_token]
  clean_input   = true
}

resource "azurecaf_name" "webui_app_service" {
  name          = "teios-ai-webui"
  resource_type = "azurerm_app_service"
  suffixes      = [var.resource_token]
  clean_input   = true
}

resource "azurecaf_name" "application_insights" {
  name          = var.app_name
  resource_type = "azurerm_application_insights"
  prefixes      = ["insights"]
  suffixes      = [var.resource_token]
  clean_input   = true
}

resource "azurecaf_name" "log_analytics_workspace" {
  name          = "teios-logs"
  resource_type = "azurerm_log_analytics_workspace"
  suffixes      = [var.resource_token]
  clean_input   = true
}

resource "azurecaf_name" "cognitive_account" {
  name          = "teios-ai"
  resource_type = "azurerm_cognitive_account"
  suffixes      = [var.resource_token]
  clean_input   = true
}

resource "azurecaf_name" "cosmosdb_account" {
  name          = "teios-cosmos"
  resource_type = "azurerm_cosmosdb_account"
  suffixes      = [var.resource_token]
  clean_input   = true
}

resource "azurecaf_name" "search_service" {
  name          = "teios-search"
  resource_type = "azurerm_search_service"
  suffixes      = [var.resource_token]
  clean_input   = true
}

resource "azurecaf_name" "storage_account" {
  name          = "teiosdocs"
  resource_type = "azurerm_storage_account"
  suffixes      = [var.resource_token]
  clean_input   = true
}

resource "azurecaf_name" "sql_server" {
  name          = "teios-sql"
  resource_type = "azurerm_mssql_server"
  suffixes      = [var.resource_token]
  clean_input   = true
}

# Local variables
locals {
  tags = {
    Application     = var.app_name
    Environment     = var.environment_name
    "azd-env-name" = var.environment_name
  }
}

# App Service Plan for API
resource "azurerm_service_plan" "api" {
  name                = azurecaf_name.app_service_plan.result
  location            = var.location
  resource_group_name = data.azurerm_resource_group.current.name
  tags                = local.tags

  os_type  = "Linux"
  sku_name = var.app_service_plan_sku
}

# WebUI App Service Plan
resource "azurerm_service_plan" "webui" {
  name                = azurecaf_name.webui_app_service_plan.result
  location            = var.location
  resource_group_name = data.azurerm_resource_group.current.name
  tags                = local.tags

  os_type  = "Linux"
  sku_name = var.app_service_plan_sku
}

# Log Analytics Workspace for Application Insights
resource "azurerm_log_analytics_workspace" "main" {
  name                = azurecaf_name.log_analytics_workspace.result
  location            = var.location
  resource_group_name = data.azurerm_resource_group.current.name
  tags                = local.tags

  sku               = "PerGB2018"
  retention_in_days = 30
}

# Application Insights for monitoring
resource "azurerm_application_insights" "main" {
  name                = azurecaf_name.application_insights.result
  location            = var.location
  resource_group_name = data.azurerm_resource_group.current.name
  tags                = local.tags

  workspace_id     = azurerm_log_analytics_workspace.main.id
  application_type = "web"
  disable_ip_masking = false
}

# Azure OpenAI Service
resource "azurerm_cognitive_account" "openai" {
  name                = azurecaf_name.cognitive_account.result
  location            = var.location
  resource_group_name = data.azurerm_resource_group.current.name
  tags                = local.tags

  kind               = "OpenAI"
  sku_name           = var.openai_sku
  public_network_access_enabled = true
  local_auth_enabled = true
  custom_subdomain_name = azurecaf_name.cognitive_account.result
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  name                = azurecaf_name.cosmosdb_account.result
  location            = var.location
  resource_group_name = data.azurerm_resource_group.current.name
  tags                = local.tags

  offer_type      = var.cosmosdb_offer_type
  kind           = "GlobalDocumentDB"
  automatic_failover_enabled = false
  multiple_write_locations_enabled = false
  public_network_access_enabled = true

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = false
  }

  dynamic "capabilities" {
    for_each = var.cosmosdb_serverless ? [1] : []
    content {
      name = "EnableServerless"
    }
  }
}

# AI Search Service
resource "azurerm_search_service" "main" {
  name                = azurecaf_name.search_service.result
  location            = var.location
  resource_group_name = data.azurerm_resource_group.current.name
  tags                = local.tags

  sku                         = var.search_sku
  replica_count              = 1
  partition_count            = 1
  hosting_mode               = "default"
  public_network_access_enabled = true
  local_authentication_enabled = true
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                = azurecaf_name.storage_account.result
  location            = var.location
  resource_group_name = data.azurerm_resource_group.current.name
  tags                = local.tags

  account_tier                      = "Standard"
  account_replication_type          = var.storage_account_replication_type
  access_tier                       = var.storage_access_tier
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = true
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  public_network_access_enabled     = true

  network_rules {
    default_action = "Allow"
  }
}

# Blob Service for Storage Account
resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "deleteafter7days"
    enabled = true
    filters {
      blob_types = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 7
      }
    }
  }
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                = azurecaf_name.sql_server.result
  location            = var.location
  resource_group_name = data.azurerm_resource_group.current.name
  tags                = local.tags

  version                      = "12.0"
  public_network_access_enabled = true

  azuread_administrator {
    login_username              = data.azurerm_user_assigned_identity.existing.name
    object_id                   = data.azurerm_user_assigned_identity.existing.principal_id
    tenant_id                   = data.azurerm_user_assigned_identity.existing.tenant_id
    azuread_authentication_only = true
  }
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name           = "teios_ai_bot_main"
  server_id      = azurerm_mssql_server.main.id
  tags           = local.tags

  collation                   = var.sql_database_collation
  max_size_gb                 = 2
  sku_name                    = "Basic"
  zone_redundant              = false
  read_scale                  = false
  storage_account_type        = "Local"
  ledger_enabled              = false
}

# SQL Server Firewall Rule to allow Azure services
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# API App Service
resource "azurerm_linux_web_app" "api" {
  name                = azurecaf_name.app_service.result
  location            = var.location
  resource_group_name = data.azurerm_resource_group.current.name
  service_plan_id     = azurerm_service_plan.api.id
  tags = merge(local.tags, {
    "azd-service-name" = "api"
  })

  https_only                    = true
  client_affinity_enabled       = false
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                                     = true
    ftps_state                                   = "Disabled"
    minimum_tls_version                          = "1.2"
    scm_minimum_tls_version                      = "1.2"
    use_32_bit_worker                            = false
    websockets_enabled                           = false
    managed_pipeline_mode                        = "Integrated"
    application_stack {
      python_version = var.python_version
    }

    dynamic "cors" {
      for_each = var.enable_cors ? [1] : []
      content {
        allowed_origins = [
          "https://${azurecaf_name.webui_app_service.result}.azurewebsites.net",
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
    "AZURE_OPENAI_ENDPOINT"               = azurerm_cognitive_account.openai.endpoint
    "AZURE_OPENAI_API_KEY"                = azurerm_cognitive_account.openai.primary_access_key
    "COSMOS_DB_ENDPOINT"                  = azurerm_cosmosdb_account.main.endpoint
    "COSMOS_DB_KEY"                       = azurerm_cosmosdb_account.main.primary_key
    "SEARCH_SERVICE_ENDPOINT"             = "https://${azurerm_search_service.main.name}.search.windows.net"
    "SEARCH_SERVICE_KEY"                  = azurerm_search_service.main.primary_key
    "STORAGE_ACCOUNT_NAME"                = azurerm_storage_account.main.name
    "STORAGE_ACCOUNT_KEY"                 = azurerm_storage_account.main.primary_access_key
    "STORAGE_ACCOUNT_CONNECTION_STRING"   = azurerm_storage_account.main.primary_connection_string
    "SQL_SERVER_NAME"                     = azurerm_mssql_server.main.fully_qualified_domain_name
    "SQL_DATABASE_NAME"                   = azurerm_mssql_database.main.name
    "SQL_CONNECTION_STRING"               = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.main.name};Authentication=Active Directory Managed Identity;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"
  }
}

# WebUI App Service
resource "azurerm_linux_web_app" "webui" {
  name                = azurecaf_name.webui_app_service.result
  location            = var.location
  resource_group_name = data.azurerm_resource_group.current.name
  service_plan_id     = azurerm_service_plan.webui.id
  tags = merge(local.tags, {
    "azd-service-name" = "webui"
  })

  https_only                    = true
  client_affinity_enabled       = false
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                     = true
    ftps_state                   = "Disabled"
    minimum_tls_version          = "1.2"
    scm_minimum_tls_version      = "1.2"
    use_32_bit_worker            = false
    websockets_enabled           = false
    managed_pipeline_mode        = "Integrated"
    
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
    "REACT_APP_API_URL"                   = "https://${azurerm_linux_web_app.api.default_hostname}"
    "VITE_API_URL"                        = "https://${azurerm_linux_web_app.api.default_hostname}"
    "NEXT_PUBLIC_API_URL"                 = "https://${azurerm_linux_web_app.api.default_hostname}"
    "VUE_APP_API_URL"                     = "https://${azurerm_linux_web_app.api.default_hostname}"
    "AZURE_OPENAI_ENDPOINT"               = azurerm_cognitive_account.openai.endpoint
    "SEARCH_SERVICE_ENDPOINT"             = "https://${azurerm_search_service.main.name}.search.windows.net"
    "STORAGE_ACCOUNT_ENDPOINT"            = azurerm_storage_account.main.primary_blob_endpoint
  }
}
