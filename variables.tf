# Variables for TEIOS AI-Driven API and WebUI Terraform deployment

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "teios-ai-api"

  validation {
    condition     = length(var.app_name) >= 1 && length(var.app_name) <= 50
    error_message = "App name must be between 1 and 50 characters."
  }
}

variable "location" {
  description = "Location for all resources"
  type        = string
  default     = "eastus2"
}

variable "environment_name" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_token" {
  description = "Fixed token to use existing resources"
  type        = string
  default     = "iymm4la6qt4mo"
}

variable "app_service_plan_sku" {
  description = "SKU for App Service Plan"
  type        = string
  default     = "B1"

  validation {
    condition = contains([
      "F1", "D1", "B1", "B2", "B3", "S1", "S2", "S3", 
      "P1V2", "P2V2", "P3V2", "P1V3", "P2V3", "P3V3"
    ], var.app_service_plan_sku)
    error_message = "App Service Plan SKU must be one of: F1, D1, B1, B2, B3, S1, S2, S3, P1V2, P2V2, P3V2, P1V3, P2V3, P3V3."
  }
}

variable "python_version" {
  description = "Python runtime version"
  type        = string
  default     = "3.11"

  validation {
    condition     = contains(["3.8", "3.9", "3.10", "3.11", "3.12"], var.python_version)
    error_message = "Python version must be one of: 3.8, 3.9, 3.10, 3.11, 3.12."
  }
}

variable "node_version" {
  description = "Node.js runtime version for WebUI"
  type        = string
  default     = "20-lts"

  validation {
    condition     = contains(["16-lts", "18-lts", "20-lts"], var.node_version)
    error_message = "Node version must be one of: 16-lts, 18-lts, 20-lts."
  }
}

variable "enable_cors" {
  description = "Enable CORS for API"
  type        = bool
  default     = true
}

variable "openai_sku" {
  description = "Azure OpenAI SKU"
  type        = string
  default     = "S0"

  validation {
    condition     = contains(["S0"], var.openai_sku)
    error_message = "OpenAI SKU must be S0."
  }
}

variable "cosmosdb_offer_type" {
  description = "Cosmos DB offer type"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard"], var.cosmosdb_offer_type)
    error_message = "Cosmos DB offer type must be Standard."
  }
}

variable "cosmosdb_serverless" {
  description = "Enable Cosmos DB Serverless"
  type        = bool
  default     = true
}

variable "search_sku" {
  description = "AI Search SKU"
  type        = string
  default     = "basic"

  validation {
    condition = contains([
      "free", "basic", "standard", "standard2", "standard3",
      "storage_optimized_l1", "storage_optimized_l2"
    ], var.search_sku)
    error_message = "Search SKU must be one of: free, basic, standard, standard2, standard3, storage_optimized_l1, storage_optimized_l2."
  }
}

variable "storage_account_replication_type" {
  description = "Storage Account replication type"
  type        = string
  default     = "LRS"

  validation {
    condition = contains([
      "LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"
    ], var.storage_account_replication_type)
    error_message = "Storage Account replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "storage_access_tier" {
  description = "Storage Account access tier"
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.storage_access_tier)
    error_message = "Storage access tier must be Hot or Cool."
  }
}

variable "sql_database_edition" {
  description = "SQL Database edition"
  type        = string
  default     = "Basic"

  validation {
    condition = contains([
      "Basic", "Standard", "Premium", "GeneralPurpose", 
      "BusinessCritical", "Hyperscale"
    ], var.sql_database_edition)
    error_message = "SQL Database edition must be one of: Basic, Standard, Premium, GeneralPurpose, BusinessCritical, Hyperscale."
  }
}

variable "sql_database_collation" {
  description = "SQL Database collation"
  type        = string
  default     = "Japanese_CI_AS"
}
