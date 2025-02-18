param location string = 'westus'
@description('Specifies the name for resources.')
param storageAccountName string = 'moduest02${uniqueString(resourceGroup().id)}'
param appServiceAppName string = 'module-app02-${uniqueString(resourceGroup().id)}'

@allowed([
  'nonprod'
  'prod'
])
param environmentType string

var storageAccountSkuName = (environmentType == 'prod') ? 'Standard_GRS' : 'Standard_LRS'

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

module appService 'modules/appService.bicep' = {
  name: 'appService'
  params: {
    location: location
    appServiceAppName: appServiceAppName
    environmentType: environmentType
  }
}

output appServiceAppHostName string = appService.outputs.appServiceAppHostName

/////////////////////
// New-AzResourceGroupDeployment -TemplateFile main.bicep -environmentType nonprod
/////////////////////





// resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
//   name: 'mkindast098'
//   location: 'eastus'
//   sku: {
//     name: 'Standard_GRS'
//   }
//   kind: 'StorageV2'
//   properties: {
//     accessTier: 'Cool'
//   }
// }

// resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
//   name: 'mkinda-app01-plan'
//   location: 'eastus'
//   sku: {
//     name: 'F1'
//   }
// }

// resource appServiceApp 'Microsoft.Web/sites@2023-12-01' = {
//   name: 'mkinda-app-01'
//   location: 'eastus'
//   properties: {
//     serverFarmId: appServicePlan.id
//     httpsOnly: true
//   }
// }

// output appServiceAppName string = appServiceApp.name

/////////////////////
// Connect-AzAccount
// $context = Get-AzSubscription -SubscriptionName 'Concierge Subscription'
// Set-AzContext $context
// Set-AzDefault -ResourceGroupName learn-d5eff839-d88f-4917-8c2c-e08147419d57
// New-AzResourceGroupDeployment -TemplateFile main.bicep
/////////////////////
