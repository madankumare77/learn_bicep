param location string = 'eastus'
param storageAccountName string = 'mkindiast02${uniqueString(resourceGroup().id)}'
param appServiceAppName string = 'mkindia-app02${uniqueString(resourceGroup().id)}'

@allowed([
  'nonprod'
  'prod'
])
param environmentType string

var appServicePlanName = 'mkindia-app02-plan02'
var storageAccountSkuName = (environmentType == 'prod') ? 'Standard_GRS' : 'Standard_LRS'
var appServicePlanSkuName = (environmentType == 'prod') ? 'P2v3' : 'F1'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSkuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
  }
}

resource appServiceApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}

/////////////////////
// New-AzResourceGroupDeployment -TemplateFile paramVar.bicep -environmentType nonprod
/////////////////////



