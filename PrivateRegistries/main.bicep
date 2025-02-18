@description('The Azure region into which the resources should be deployed.')
param location string = 'westus'

@description('The name of the App Service app.')
param appServiceAppName string = 'mk-${uniqueString(resourceGroup().id)}'

@description('The name of the App Service plan SKU.')
param appServicePlanSkuName string = 'F1'

var appServicePlanName = 'mk-dog-plan'

module website 'br/ToyCompanyRegistry:website:v1' = {
  name: 'mk-dog-websitev1'
  params: {
    appServiceAppName: appServiceAppName
    appServicePlanName: appServicePlanName
    appServicePlanSkuName: appServicePlanSkuName
    location: location
  }
}

module cdn 'br/ToyCompanyRegistry:cdn:v1' = {
  name: 'mk-dog-cdnv1'
  params: {
    httpsOnly: true
    originHostName: website.outputs.appServiceAppHostName
  }
}
