# RAG AI-Driven Chatbot Infrastructure
# Terraform configuration for Azure resources with Managed Identity security

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
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

# Data source for existing resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Resource naming using azurecaf
resource "azurecaf_name" "api_app_service" {
  name          = var.app_name
  resource_type = "azurerm_app_service"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "webui_app_service" {
  name          = "${var.app_name}-webui"
  resource_type = "azurerm_app_service"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "app_service_plan" {
  name          = "${var.app_name}-plan"
  resource_type = "azurerm_app_service_plan"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "webui_app_service_plan" {
  name          = "${var.app_name}-webui-plan"
  resource_type = "azurerm_app_service_plan"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "openai" {
  name          = "${var.app_name}-ai"
  resource_type = "azurerm_cognitive_account"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "cosmos_db" {
  name          = "${var.app_name}-cosmos"
  resource_type = "azurerm_cosmosdb_account"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "search_service" {
  name          = "${var.app_name}-search"
  resource_type = "azurerm_search_service"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "storage_account" {
  name          = "${var.app_name}docs"
  resource_type = "azurerm_storage_account"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "sql_server" {
  name          = "${var.app_name}-sql"
  resource_type = "azurerm_mssql_server"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "log_analytics" {
  name          = "${var.app_name}-logs"
  resource_type = "azurerm_log_analytics_workspace"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "app_insights" {
  name          = "${var.app_name}-insights"
  resource_type = "azurerm_application_insights"
  suffixes      = [var.environment]
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = azurecaf_name.log_analytics.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Application   = var.app_name
    Environment   = var.environment
    "azd-env-name" = var.environment
  }
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = azurecaf_name.app_insights.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = {
    Application   = var.app_name
    Environment   = var.environment
    "azd-env-name" = var.environment
  }
}

# App Service Plans
resource "azurerm_service_plan" "api" {
  name                = azurecaf_name.app_service_plan.result
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku

  tags = {
    Application   = var.app_name
    Environment   = var.environment
    "azd-env-name" = var.environment
  }
}

resource "azurerm_service_plan" "webui" {
  name                = azurecaf_name.webui_app_service_plan.result
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku

  tags = {
    Application   = var.app_name
    Environment   = var.environment
    "azd-env-name" = var.environment
  }
}

# Azure OpenAI Service
resource "azurerm_cognitive_account" "openai" {
  name                = azurecaf_name.openai.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  kind                = "OpenAI"
  sku_name            = var.openai_sku
  
  custom_subdomain_name = azurecaf_name.openai.result
  public_network_access_enabled = true

  tags = {
    Application   = var.app_name
    Environment   = var.environment
    "azd-env-name" = var.environment
  }
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  name                = azurecaf_name.cosmos_db.result
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  offer_type          = "Standard"
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

  capabilities {
    name = "EnableServerless"
  }

  public_network_access_enabled = true
  automatic_failover_enabled    = false
  multiple_write_locations_enabled = false

  tags = {
    Application   = var.app_name
    Environment   = var.environment
    "azd-env-name" = var.environment
  }
}

# AI Search Service
resource "azurerm_search_service" "main" {
  name                = azurecaf_name.search_service.result
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = var.search_sku
  replica_count       = 1
  partition_count     = 1

  public_network_access_enabled = true

  tags = {
    Application   = var.app_name
    Environment   = var.environment
    "azd-env-name" = var.environment
  }
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = azurecaf_name.storage_account.result
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = var.storage_account_replication_type
  access_tier              = var.storage_access_tier
  
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  default_to_oauth_authentication = false
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true

  network_rules {
    default_action = "Allow"
  }

  tags = {
    Application   = var.app_name
    Environment   = var.environment
    "azd-env-name" = var.environment
  }
}

# Storage Account Blob Service
resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "DeleteAfter7Days"
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
  name                         = azurecaf_name.sql_server.result
  resource_group_name          = data.azurerm_resource_group.main.name
  location                     = data.azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  public_network_access_enabled = true

  tags = {
    Application   = var.app_name
    Environment   = var.environment
    "azd-env-name" = var.environment
  }
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name           = "${var.app_name}_ai_bot_main"
  server_id      = azurerm_mssql_server.main.id
  collation      = var.sql_database_collation
  max_size_gb    = 2
  sku_name       = "Basic"
  zone_redundant = false
  
  tags = {
    Application   = var.app_name
    Environment   = var.environment
    "azd-env-name" = var.environment
  }
}

# SQL Firewall Rule for Azure Services
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# API App Service
resource "azurerm_linux_web_app" "api" {
  name                = azurecaf_name.api_app_service.result
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.api.id

  https_only = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                         = true
    ftps_state                       = "Disabled"
    minimum_tls_version              = "1.2"
    scm_minimum_tls_version          = "1.2"
    use_32_bit_worker                = false
    websockets_enabled               = false
    managed_pipeline_mode            = "Integrated"

    application_stack {
      python_version = var.python_version
    }

    cors {
      allowed_origins     = [
        "https://${azurecaf_name.webui_app_service.result}.azurewebsites.net",
        "http://localhost:3000",
        "http://localhost:5173",
        "http://localhost:8080"
      ]
      support_credentials = true
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "8000"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"     = "true"
    "ENABLE_ORYX_BUILD"                   = "true"
    "ENVIRONMENT"                         = var.environment
    "PYTHON_ENABLE_GUNICORN_MULTIWORKERS" = "true"
    
    # Azure service endpoints (using Managed Identity)
    "AZURE_OPENAI_ENDPOINT"      = azurerm_cognitive_account.openai.endpoint
    "COSMOS_DB_ENDPOINT"         = azurerm_cosmosdb_account.main.endpoint
    "SEARCH_SERVICE_ENDPOINT"    = "https://${azurerm_search_service.main.name}.search.windows.net"
    "STORAGE_ACCOUNT_NAME"       = azurerm_storage_account.main.name
    "STORAGE_ACCOUNT_ENDPOINT"   = azurerm_storage_account.main.primary_blob_endpoint
    "SQL_SERVER_NAME"            = azurerm_mssql_server.main.fully_qualified_domain_name
    "SQL_DATABASE_NAME"          = azurerm_mssql_database.main.name
    "SQL_CONNECTION_STRING"      = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.main.name};Authentication=Active Directory Managed Identity;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"
    
    # Application Insights
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
  }

  tags = {
    Application        = var.app_name
    Environment        = var.environment
    "azd-env-name"     = var.environment
    "azd-service-name" = "api"
  }

  depends_on = [
    azurerm_service_plan.api,
    azurerm_cognitive_account.openai,
    azurerm_cosmosdb_account.main,
    azurerm_search_service.main,
    azurerm_storage_account.main,
    azurerm_mssql_server.main,
    azurerm_mssql_database.main
  ]
}

# WebUI App Service
resource "azurerm_linux_web_app" "webui" {
  name                = azurecaf_name.webui_app_service.result
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.webui.id

  https_only = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                         = true
    ftps_state                       = "Disabled"
    minimum_tls_version              = "1.2"
    scm_minimum_tls_version          = "1.2"
    use_32_bit_worker                = false
    websockets_enabled               = false
    managed_pipeline_mode            = "Integrated"

    application_stack {
      node_version = var.node_version
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "3000"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"     = "true"
    "ENABLE_ORYX_BUILD"                   = "true"
    "ENVIRONMENT"                         = var.environment
    
    # API endpoints
    "REACT_APP_API_URL"       = "https://${azurerm_linux_web_app.api.default_hostname}"
    "VITE_API_URL"            = "https://${azurerm_linux_web_app.api.default_hostname}"
    "NEXT_PUBLIC_API_URL"     = "https://${azurerm_linux_web_app.api.default_hostname}"
    "VUE_APP_API_URL"         = "https://${azurerm_linux_web_app.api.default_hostname}"
    
    # Azure service endpoints
    "AZURE_OPENAI_ENDPOINT"   = azurerm_cognitive_account.openai.endpoint
    "SEARCH_SERVICE_ENDPOINT" = "https://${azurerm_search_service.main.name}.search.windows.net"
    "STORAGE_ACCOUNT_ENDPOINT" = azurerm_storage_account.main.primary_blob_endpoint
    
    # Application Insights
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
  }

  tags = {
    Application        = var.app_name
    Environment        = var.environment
    "azd-env-name"     = var.environment
    "azd-service-name" = "webui"
  }

  depends_on = [
    azurerm_service_plan.webui,
    azurerm_linux_web_app.api,
    azurerm_cognitive_account.openai,
    azurerm_search_service.main,
    azurerm_storage_account.main
  ]
}

# Role Assignments for Managed Identity Authentication
resource "azurerm_role_assignment" "api_openai_user" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_linux_web_app.api.identity[0].principal_id
  principal_type       = "ServicePrincipal"

  depends_on = [azurerm_linux_web_app.api]
}

resource "azurerm_role_assignment" "api_cosmos_contributor" {
  scope                = azurerm_cosmosdb_account.main.id
  role_definition_name = "Cosmos DB Built-in Data Contributor"
  principal_id         = azurerm_linux_web_app.api.identity[0].principal_id
  principal_type       = "ServicePrincipal"

  depends_on = [azurerm_linux_web_app.api]
}

resource "azurerm_role_assignment" "api_search_contributor" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Service Contributor"
  principal_id         = azurerm_linux_web_app.api.identity[0].principal_id
  principal_type       = "ServicePrincipal"

  depends_on = [azurerm_linux_web_app.api]
}

resource "azurerm_role_assignment" "api_storage_blob_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.api.identity[0].principal_id
  principal_type       = "ServicePrincipal"

  depends_on = [azurerm_linux_web_app.api]
}

resource "azurerm_role_assignment" "webui_storage_blob_reader" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_linux_web_app.webui.identity[0].principal_id
  principal_type       = "ServicePrincipal"

  depends_on = [azurerm_linux_web_app.webui]
}
