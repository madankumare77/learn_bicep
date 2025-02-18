@description('The Azure region into which the resources should be deployed.')
param location string

@description('The type of environment. This must be nonprod or prod.')
@allowed([
  'nonprod'
  'prod'
])
param environmentType string

@description('The name of the storage account to deploy. This name must be globally unique.')
param storageAccountName string

@description('The name of the queue to deploy for processing orders.')
param processOrderQueueName string

@description('The name of the App Service app. This name must be globally unique.')
param appServiceAppName string

var appServicePlanName = 'toy-website-plan'
var appServicePlanSkuName = (environmentType == 'prod') ? 'P2v3' : 'F1'
var appServicePlanTierName = (environmentType == 'prod') ? 'PremiumV3' : 'Free'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
    tier: appServicePlanTierName
  }
}

resource appServiceApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'StorageAccountName'
          value: storageAccountName
        }
        {
          name: 'ProcessOrderQueueName'
          value: processOrderQueueName
        }
      ]
    }
  }
}
