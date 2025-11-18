param location string
param sqlServerName string
param sqlAdminlogin string
param subnetId string

@secure()
param sqlAdminPassword string

resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminlogin
    administratorLoginPassword: sqlAdminPassword
  }
}

resource productionDB 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: '${sqlServerName}-proddb'
  location: location
  properties: {
    catalogCollation: 'DATABASE_DEFAULT'
  }
  sku: {
    name: 'S3'
  }
}

resource stagingDB 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: '${sqlServerName}-stagingdb'
  location: location
  properties: {
    catalogCollation: 'DATABASE_DEFAULT'
  }
  sku: {
    name: 'S3'
  }
}

resource sqlvnet 'Microsoft.Sql/servers/virtualNetworkRules@2024-05-01-preview' = {
  parent: sqlServer
  name: '${sqlServerName}-vnet'
  properties: {
    ignoreMissingVnetServiceEndpoint: false
    virtualNetworkSubnetId: subnetId
  }
}
