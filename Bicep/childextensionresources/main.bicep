param cosmosDBAccountName string = 'mkcosmos-${uniqueString(resourceGroup().id)}'
param cosmosDBDatabaseThroughput int = 800
param location string = resourceGroup().location
param storageAccountName string = 'manualst001'

var cosmosDBDatabaseName = 'mkdb'
var cosmosDBContainerName = 'FlightTests'
var cosmosDBContainerPartitionKey = '/droneId'
var logAnalyticsWorkspaceName = 'ToyLogs'
var cosmosDBAccountDiagnosticSettingsName = 'route-logs-to-log-analytics'
var storageAccountBlobDiagnosticSettingsName = 'route-logs-to-log-analytics'

resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: cosmosDBAccountName
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
      }
    ]
  }
  resource cosmosDBDatabase2 'sqlDatabases' = {
    name: '${cosmosDBDatabaseName}2'
    properties: {
      resource: {
        id: '${cosmosDBDatabaseName}2'
      }
      options: {
        throughput: cosmosDBDatabaseThroughput
      }
    }
    resource container2 'containers' = {
      name: '${cosmosDBContainerName}2'
      properties: {
        resource: {
          id: '${cosmosDBContainerName}2'
          partitionKey: {
            kind: 'Hash'
            paths: [
              cosmosDBContainerPartitionKey
            ]
          }
        }
        options: {}
      }
    }
    resource container3 'containers' = {
      name: '${cosmosDBContainerName}3'
      properties: {
        resource: {
          id: '${cosmosDBContainerName}3'
          partitionKey: {
            kind: 'Hash'
            paths: [
              cosmosDBContainerPartitionKey
            ]
          }
        }
        options: {}
      }
    }
  }
}

resource cosmosDBDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmosDBAccount
  name: cosmosDBDatabaseName
  properties: {
    resource: {
      id: cosmosDBDatabaseName
    }
    options: {
      throughput: cosmosDBDatabaseThroughput
    }
  }
  resource container 'containers' = {
    name: cosmosDBContainerName
    properties: {
      resource: {
        id: cosmosDBContainerName
        partitionKey: {
          kind: 'Hash'
          paths: [
            cosmosDBContainerPartitionKey
          ]
        }
      }
      options: {}
    }
  }
}

//New-AzOperationalInsightsWorkspace -Name ToyLogs -Location eastus
// Created manually in the same RG
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource cosmosDBAccountDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: cosmosDBAccount
  name: cosmosDBAccountDiagnosticSettingsName
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'DataPlaneRequests'
        enabled: true
      }
    ]
  }
}

//New-AzStorageAccount -Name manualst001 -Location eastus -SkuName Standard_LRS
// created storage account manually
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName

  resource blobService 'blobServices' existing = {
    name: 'default'
  }
}

resource storageAccountBlobDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: storageAccount::blobService
  name: storageAccountBlobDiagnosticSettingsName
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
  }
}

//Connect-AzAccount
//$context = Get-AzSubscription -SubscriptionName 'Concierge Subscription'
//Set-AzContext $context
//New-AzResourceGroupDeployment -TemplateFile main.bicep
