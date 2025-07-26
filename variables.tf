# Variables for RAG AI-Driven API and WebUI Terraform configuration

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "rag-ai-api"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,50}$", var.app_name))
    error_message = "App name must be 1-50 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US 2"
}

variable "environment_name" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment_name)
    error_message = "Environment name must be one of: dev, staging, prod."
  }
}

variable "resource_token" {
  description = "Fixed token to use for existing resources"
  type        = string
  default     = "iymm4la6qt4mo"
}

variable "app_service_plan_sku" {
  description = "SKU for App Service Plan"
  type        = string
  default     = "B1"
  
  validation {
    condition = contains([
      "F1", "B1", "B2", "S1", "S2", "S3", "P1V2", "P2V2", "P3V2"
    ], var.app_service_plan_sku)
    error_message = "App Service Plan SKU must be one of: F1, B1, B2, S1, S2, S3, P1V2, P2V2, P3V2."
  }
}

variable "python_version" {
  description = "Python runtime version"
  type        = string
  default     = "3.11"
  
  validation {
    condition     = contains(["3.9", "3.10", "3.11"], var.python_version)
    error_message = "Python version must be one of: 3.9, 3.10, 3.11."
  }
}

variable "node_version" {
  description = "Node.js runtime version for WebUI"
  type        = string
  default     = "20-lts"
  
  validation {
    condition     = contains(["18-lts", "20-lts"], var.node_version)
    error_message = "Node version must be one of: 18-lts, 20-lts."
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

variable "cosmos_db_offer_type" {
  description = "Cosmos DB offer type"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Standard"], var.cosmos_db_offer_type)
    error_message = "Cosmos DB offer type must be Standard."
  }
}

variable "cosmos_db_serverless" {
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

variable "storage_account_sku" {
  description = "Storage Account replication type"
  type        = string
  default     = "LRS"
  
  validation {
    condition = contains([
      "LRS", "GRS", "RAGRS", "ZRS"
    ], var.storage_account_sku)
    error_message = "Storage Account SKU must be one of: LRS, GRS, RAGRS, ZRS."
  }
}

variable "storage_access_tier" {
  description = "Storage Account access tier"
  type        = string
  default     = "Hot"
  
  validation {
    condition     = contains(["Hot", "Cool"], var.storage_access_tier)
    error_message = "Storage access tier must be one of: Hot, Cool."
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
