param appname string
param location string
param subnetId string
 
resource appServiceplan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: '${appname}-plan'
  location: location
  sku: {
    name: 'P1v3'
    tier: 'PremiumV3'
  }
}

resource appService 'Microsoft.Web/sites@2024-04-01' = {
  name: appname
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServiceplan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.3'
    }
    virtualNetworkSubnetId: subnetId
  }
}

resource productionSlot 'Microsoft.Web/sites/slots@2024-04-01' = {
  parent: appService
  name: '${appname}-prodslot'
  location: location
  properties: {
    siteConfig: {
      minTlsVersion: '1.3'
      appSettings: [
        {
          name: 'Environment'
          value: 'production'
        }
      ]
    }
  }
}

resource stagingSlot 'Microsoft.Web/sites/slots@2024-04-01' = {
  parent: appService
  name: '${appname}-stagingslot'
  location: location
  properties: {
    siteConfig: {
      minTlsVersion: '1.3'
      appSettings: [
        {
          name: 'Environment'
          value: 'Staging'
        }
      ]
    }
  }
}
