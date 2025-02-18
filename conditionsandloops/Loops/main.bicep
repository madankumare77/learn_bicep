@description('The Azure regions into which the resources should be deployed.')
param locations array = [
  'westus'
  'eastus2'
]

@secure()
@description('The administrator login username for the SQL server.')
param sqlServerAdministratorLogin string

@secure()
@description('The administrator login password for the SQL server.')
param sqlServerAdministratorLoginPassword string

@description('The IP address range for all virtual networks to use.')
param virtualNetworkAddressPrefix string = '10.10.0.0/16'

@description('The name and IP address range for each subnet in the virtual networks.')
param subnets array = [
  {
    name: 'frontend'
    ipAddressRange: '10.10.5.0/24'
  }
  {
    name: 'backend'
    ipAddressRange: '10.10.10.0/24'
  }
]

var subnetProperties = [for subnet in subnets: {
  name: subnet.name
  properties: {
    addressPrefix: subnet.ipAddressRange
  }
}]

module databases 'modules/database.bicep' = [for location in locations: {
  name: 'database-${location}'
  params: {
    location: location
    sqlServerAdministratorLogin: sqlServerAdministratorLogin
    sqlServerAdministratorLoginPassword: sqlServerAdministratorLoginPassword
  }
}]

resource virtualNetworks 'Microsoft.Network/virtualNetworks@2024-01-01' = [for location in locations: {
  name: 'mkvent-${location}'
  location: location
  properties:{
    addressSpace:{
      addressPrefixes:[
        virtualNetworkAddressPrefix
      ]
    }
    subnets: subnetProperties
  }
}]

output serverInfo array = [for i in range(0, length(locations)): {
  name: databases[i].outputs.serverName
  location: databases[i].outputs.location
  fullyQualifiedDomainName: databases[i].outputs.serverFullyQualifiedDomainName
}]

// App service
@description('The Azure region into which the resources should be deployed.')
param location string = 'westus'

@description('The name of the App Service app.')
param appServiceAppName string = 'toymk-${uniqueString(resourceGroup().id)}'

@description('The name of the App Service plan SKU.')
param appServicePlanSkuName string = 'F1'

var appServicePlanName = 'toymk-cdr-plan'

module app 'modules/app.bicep' = {
  name: 'app'
  params: {
    location: location
    appServiceAppName: appServiceAppName
    appServicePlanName: appServicePlanName
    appServicePlanSkuName: appServicePlanSkuName
  }
}

@description('Indicates whether a CDN should be deployed.')
param deployCdn bool = true

module cdn 'modules/cdn.bicep' = if (deployCdn) {
  name: 'toy-mk-cdn'
  params: {
    httpsOnly: true
    originHostName: app.outputs.appServiceAppHostName
  }
}

@description('The host name to use to access the website.')
output websiteHostName string = deployCdn ? cdn.outputs.endpointHostName : app.outputs.appServiceAppHostName

// New-AzResourceGroupDeployment -TemplateFile main.bicep

//mkadmin
//5c:u%%9S!-V}jYv*
