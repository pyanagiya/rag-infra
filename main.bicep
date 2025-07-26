// Main Bicep template for TEIOS AI-Driven API and WebUI
// Azure Developer CLI compatible deployment

targetScope = 'resourceGroup'

@minLength(1)
@maxLength(50)
@description('Name of the application')
param appName string = 'teios-ai-api'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, staging, prod)')
param environmentName string

@description('SKU for App Service Plan')
@allowed(['F1', 'B1', 'B2', 'S1', 'S2', 'S3', 'P1V2', 'P2V2', 'P3V2'])
param appServicePlanSku string = 'B1'

@description('Python runtime version')
@allowed(['3.9', '3.10', '3.11'])
param pythonVersion string = '3.11'

@description('Node.js runtime version for WebUI')
@allowed(['18-lts', '20-lts'])
param nodeVersion string = '20-lts'

@description('Enable CORS for API')
param enableCors bool = true

@description('Azure OpenAI SKU')
@allowed(['S0'])
param openAiSku string = 'S0'

@description('Cosmos DB offer type')
@allowed(['Standard'])
param cosmosDbOfferType string = 'Standard'

@description('Enable Cosmos DB Serverless')
param cosmosDbServerless bool = true

@description('AI Search SKU')
@allowed(['free', 'basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'])
param searchSku string = 'basic'

@description('Storage Account SKU')
@allowed(['Standard_LRS', 'Standard_GRS', 'Standard_RAGRS', 'Standard_ZRS', 'Premium_LRS'])
param storageAccountSku string = 'Standard_LRS'

@description('Storage Account access tier')
@allowed(['Hot', 'Cool'])
param storageAccessTier string = 'Hot'

@description('SQL Database edition')
@allowed(['Basic', 'Standard', 'Premium', 'GeneralPurpose', 'BusinessCritical', 'Hyperscale'])
param sqlDatabaseEdition string = 'Basic'

@description('SQL Database collation')
param sqlDatabaseCollation string = 'Japanese_CI_AS'

// Variables
var resourceToken = 'iymm4la6qt4mo' // Fixed token to use existing resources
var tags = {
  Application: appName
  Environment: environmentName
  'azd-env-name': environmentName
}

// Reference to existing User-Assigned Managed Identity
resource existingManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'teios-ai-api-identity-${resourceToken}'
}

// App Service Plan for API
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${appName}-plan-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: appServicePlanSku
  }
  kind: 'linux'
  properties: {
    reserved: true // Required for Linux
  }
}

// WebUI App Service Plan
resource webuiAppServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'teios-ai-webui-plan-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: appServicePlanSku
  }
  kind: 'linux'
  properties: {
    reserved: true // Required for Linux
  }
}

// API App Service
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: '${appName}-${resourceToken}'
  location: location
  tags: union(tags, {
    'azd-service-name': 'api'
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|${pythonVersion}'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      use32BitWorkerProcess: false
      webSocketsEnabled: false
      managedPipelineMode: 'Integrated'
      cors: enableCors ? {
        allowedOrigins: [
          'https://teios-ai-webui-${resourceToken}.azurewebsites.net'
          'http://localhost:3000'
          'http://localhost:5173'
          'http://localhost:8080'
        ]
        supportCredentials: true
      } : null
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8000'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'true'
        }
        {
          name: 'ENVIRONMENT'
          value: environmentName
        }
        {
          name: 'PYTHON_ENABLE_GUNICORN_MULTIWORKERS'
          value: 'true'
        }
        {
          name: 'AZURE_OPENAI_ENDPOINT'
          value: openAiService.properties.endpoint
        }
        {
          name: 'AZURE_OPENAI_API_KEY'
          value: openAiService.listKeys().key1
        }
        {
          name: 'COSMOS_DB_ENDPOINT'
          value: cosmosDbAccount.properties.documentEndpoint
        }
        {
          name: 'COSMOS_DB_KEY'
          value: cosmosDbAccount.listKeys().primaryMasterKey
        }
        {
          name: 'SEARCH_SERVICE_ENDPOINT'
          value: 'https://${searchService.name}.search.windows.net'
        }
        {
          name: 'SEARCH_SERVICE_KEY'
          value: searchService.listAdminKeys().primaryKey
        }
        {
          name: 'STORAGE_ACCOUNT_NAME'
          value: storageAccount.name
        }
        {
          name: 'STORAGE_ACCOUNT_KEY'
          value: storageAccount.listKeys().keys[0].value
        }
        {
          name: 'STORAGE_ACCOUNT_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'SQL_SERVER_NAME'
          value: sqlServer.properties.fullyQualifiedDomainName
        }
        {
          name: 'SQL_DATABASE_NAME'
          value: sqlDatabase.name
        }
        {
          name: 'SQL_CONNECTION_STRING'
          value: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Database=${sqlDatabase.name};Authentication=Active Directory Managed Identity;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;'
        }
      ]
    }
    clientAffinityEnabled: false
  }
}

// WebUI App Service
resource webuiAppService 'Microsoft.Web/sites@2023-01-01' = {
  name: 'teios-ai-webui-${resourceToken}'
  location: location
  tags: union(tags, {
    'azd-service-name': 'webui'
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: webuiAppServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|${nodeVersion}'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      use32BitWorkerProcess: false
      webSocketsEnabled: false
      managedPipelineMode: 'Integrated'
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITES_PORT'
          value: '3000'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'true'
        }
        {
          name: 'ENVIRONMENT'
          value: environmentName
        }
        {
          name: 'REACT_APP_API_URL'
          value: 'https://${appService.properties.defaultHostName}'
        }
        {
          name: 'VITE_API_URL'
          value: 'https://${appService.properties.defaultHostName}'
        }
        {
          name: 'NEXT_PUBLIC_API_URL'
          value: 'https://${appService.properties.defaultHostName}'
        }
        {
          name: 'VUE_APP_API_URL'
          value: 'https://${appService.properties.defaultHostName}'
        }
        {
          name: 'AZURE_OPENAI_ENDPOINT'
          value: openAiService.properties.endpoint
        }
        {
          name: 'SEARCH_SERVICE_ENDPOINT'
          value: 'https://${searchService.name}.search.windows.net'
        }
        {
          name: 'STORAGE_ACCOUNT_ENDPOINT'
          value: storageAccount.properties.primaryEndpoints.blob
        }
      ]
    }
    clientAffinityEnabled: false
  }
}

// Application Insights for monitoring
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${appName}-insights-${resourceToken}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    DisableIpMasking: false
    DisableLocalAuth: false
    ForceCustomerStorageForProfiler: false
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Log Analytics Workspace for Application Insights
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'teios-logs-${resourceToken}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Azure OpenAI Service
resource openAiService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: 'teios-ai-${resourceToken}'
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: openAiSku
  }
  properties: {
    customSubDomainName: 'teios-ai-${resourceToken}'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

// Cosmos DB Account
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: 'teios-cosmos-${resourceToken}'
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: cosmosDbOfferType
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxIntervalInSeconds: 5
      maxStalenessPrefix: 100
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: cosmosDbServerless ? [
      {
        name: 'EnableServerless'
      }
    ] : []
    publicNetworkAccess: 'Enabled'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
  }
}

// AI Search Service
resource searchService 'Microsoft.Search/searchServices@2023-11-01' = {
  name: 'teios-search-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: searchSku
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'enabled'
    networkRuleSet: {
      ipRules: []
    }
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    disableLocalAuth: false
    authOptions: {
      apiKeyOnly: {}
    }
  }
}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'teiosdocs${resourceToken}'
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: storageAccountSku
  }
  properties: {
    accessTier: storageAccessTier
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false
    dnsEndpointType: 'Standard'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
  }
}

// Blob Service for Storage Account
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-02-01-preview' = {
  name: 'teios-sql-${resourceToken}'
  location: location
  tags: tags
  properties: {
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    administrators: {
      azureADOnlyAuthentication: true
      administratorType: 'ActiveDirectory'
      principalType: 'Application'
      login: existingManagedIdentity.name
      sid: existingManagedIdentity.properties.principalId
      tenantId: existingManagedIdentity.properties.tenantId
    }
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-02-01-preview' = {
  parent: sqlServer
  name: 'teios_ai_bot_main'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: sqlDatabaseEdition
  }
  properties: {
    collation: sqlDatabaseCollation
    maxSizeBytes: 2147483648 // 2GB
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Local'
    isLedgerOn: false
  }
}

// SQL Server Firewall Rule to allow Azure services
resource sqlServerFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-02-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Outputs
@description('The name of the API App Service')
output AZURE_WEBAPP_NAME string = appService.name

@description('The URL of the API App Service')
output AZURE_WEBAPP_URL string = 'https://${appService.properties.defaultHostName}'

@description('The name of the WebUI App Service')
output AZURE_WEBUI_NAME string = webuiAppService.name

@description('The URL of the WebUI App Service')
output AZURE_WEBUI_URL string = 'https://${webuiAppService.properties.defaultHostName}'

@description('The resource ID of the API App Service')
output appServiceId string = appService.id

@description('The resource ID of the WebUI App Service')
output webuiAppServiceId string = webuiAppService.id

@description('The principal ID of the API App Service managed identity')
output appServicePrincipalId string = appService.identity.principalId

@description('The principal ID of the WebUI App Service managed identity')
output webuiAppServicePrincipalId string = webuiAppService.identity.principalId

@description('Application Insights Instrumentation Key')
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('Application Insights Connection String')
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString

@description('Azure OpenAI Service endpoint')
output openAiEndpoint string = openAiService.properties.endpoint

@description('Azure OpenAI Service name')
output openAiServiceName string = openAiService.name

@description('Cosmos DB account endpoint')
output cosmosDbEndpoint string = cosmosDbAccount.properties.documentEndpoint

@description('Cosmos DB account name')
output cosmosDbAccountName string = cosmosDbAccount.name

@description('AI Search service endpoint')
output searchServiceEndpoint string = 'https://${searchService.name}.search.windows.net'

@description('AI Search service name')
output searchServiceName string = searchService.name

@description('Storage Account name')
output storageAccountName string = storageAccount.name

@description('Storage Account blob endpoint')
output storageAccountBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('SQL Server name')
output sqlServerName string = sqlServer.name

@description('SQL Database name')
output sqlDatabaseName string = sqlDatabase.name

@description('SQL Server FQDN')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
