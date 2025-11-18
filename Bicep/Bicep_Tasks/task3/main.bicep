// 3. Create an Bicep template with Azure App Service, Azure Application Insights, 
// including the configuration for performance and availability metrics, 
// as well as network settings to ensure the service is exposed via private endpoint only.

param Location string = resourceGroup().location

@description('The name of the App Service app. This name must be globally unique.')
param appServiceAppName string
var appServicePlanSkuName = 'F1'
var appServicePlanTierName = 'Free'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${appServiceAppName}-plan'
  location: Location
  sku: {
    name: appServicePlanSkuName
    tier: appServicePlanTierName
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = { 
  name: 'appinsights'
  location: Location
  kind: 'web'
  properties: {Application_Type: 'web'}
}

resource appServiceApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceAppName
  location: Location
  properties: {
    serverFarmId: appServicePlan.id
  }
}

// Creates a virtual network
var vnetname = '${appServiceAppName}-vnet'
var snet1    = '${appServiceAppName}-snet1'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetname
  location: Location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: snet1
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      // {
      //   name: '${keyVaultName}-snet2'
      //   properties: {
      //     addressPrefix: '10.0.1.0/24'
      //   }
      // }
    ]
  }
}

//private endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${appServiceAppName}-pe'
  location: Location
  properties:{ 
    subnet: {
      id: virtualNetwork.properties.subnets[0].id //resourceId('Microsoft.Network/virtualNetworks/subnets', vnetname, snet1)
    }
    privateLinkServiceConnections: [
      { 
        name: '${appServiceAppName}-pe-connection'
        properties:{ 
          privateLinkServiceId: appServiceApp.id
          groupIds: ['sites']
        }
      }
    ]
  }
}

//Diagnostic settings for Log Analytics
param workspacesku string = 'Free'

@description('Number of days to retain data.')
param retentionInDays int = 30

@description('true to use resource or workspace permissions. false to require workspace permissions.')
param resourcePermissions bool = true

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${appServiceAppName}-law'
  location: Location
  properties: {
    sku: {
      name: workspacesku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: resourcePermissions
    }
  }
}

resource diagnosticsetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appServiceAppName}-diag'
  properties:{
    workspaceId: workspace.id
    logs:[
      { 
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      { 
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      { 
        category: 'AppServiceAppLogs'
        enabled: true
      }
    ]
    metrics: [ {
      enabled: true
      category: 'AllMetrics'
    }]
  }
  scope: appServiceApp
}
