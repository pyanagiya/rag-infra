# RAG AI-Driven Chatbot Infrastructure Variables

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "rag-ai-api"

  validation {
    condition     = length(var.app_name) >= 1 && length(var.app_name) <= 50
    error_message = "App name must be between 1 and 50 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
  default     = "teios-ai-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Japan East"
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

variable "openai_sku" {
  description = "Azure OpenAI SKU"
  type        = string
  default     = "S0"

  validation {
    condition     = contains(["S0"], var.openai_sku)
    error_message = "OpenAI SKU must be: S0."
  }
}

variable "cosmos_db_offer_type" {
  description = "Cosmos DB offer type"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard"], var.cosmos_db_offer_type)
    error_message = "Cosmos DB offer type must be: Standard."
  }
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
      "LRS", "GRS", "RAGRS", "ZRS"
    ], var.storage_account_replication_type)
    error_message = "Storage replication type must be one of: LRS, GRS, RAGRS, ZRS."
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

variable "sql_database_collation" {
  description = "SQL Database collation"
  type        = string
  default     = "Japanese_CI_AS"
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
  default     = "TempPassword123!"

  validation {
    condition     = length(var.sql_admin_password) >= 8
    error_message = "SQL admin password must be at least 8 characters long."
  }
}
