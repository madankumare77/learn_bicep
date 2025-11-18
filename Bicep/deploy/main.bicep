@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The type of environment. This must be nonprod or prod.')
@allowed([
  'nonprod'
  'prod'
])
param environmentType string

@description('The name of the App Service app. This name must be globally unique.')
param appServiceAppName string = 'toyweb-${uniqueString(resourceGroup().id)}'

@description('The name of the Cosmos DB account. This name must be globally unique.')
param cosmosDBAccountName string = 'toyweb-${uniqueString(resourceGroup().id)}'

@description('Specifies whether the storage account is ready to be deployed.')
param storageAccountReady bool = false

var storageAccountName = 'mkst-${uniqueString(resourceGroup().id)}'
var storageAccountSkuName = (environmentType == 'prod') ? 'Standard_GRS' : 'Standard_LRS'
var processOrderQueueName = 'processorder'

module appService 'modules/app-service.bicep' = {
  name: 'app-service'
  params: {
    location: location
    environmentType: environmentType
    appServiceAppName: appServiceAppName
    storageAccountName: storageAccount.name
    processOrderQueueName: storageAccount::queueServices::processOrderQueue.name
  }
}

module cosmosDB 'modules/cosmos-db.bicep' = {
  name: 'cosmos-db'
  params: {
    location: location
    environmentType: environmentType
    cosmosDBAccountName: cosmosDBAccountName
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSkuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }

  resource queueServices 'queueServices' existing = {
    name: 'default'

    resource processOrderQueue 'queues' = {
      name: processOrderQueueName
    }
  }
}




