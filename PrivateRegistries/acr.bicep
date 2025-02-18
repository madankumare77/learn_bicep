@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string = 'acrmk${uniqueString(resourceGroup().id)}'

@description('Provide a location for the registry.')
param location string = resourceGroup().location

@description('Provide a tier of your Azure Container Registry.')
param acrSku string = 'Basic'

resource acrResource 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: false
  }
}

@description('Output the login server property for later use')
output loginServer string = acrResource.properties.loginServer


//New-AzResourceGroupDeployment -TemplateFile acr.bicep

// bicep publish website.bicep --target 'br:acrmklv5zjckjoctgm.azurecr.io/website:v1'

// bicep publish cdn.bicep --target 'br:acrmklv5zjckjoctgm.azurecr.io/cdn:v1'
