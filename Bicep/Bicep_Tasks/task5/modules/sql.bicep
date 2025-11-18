param sqlServername string = 'mksqlserver'
param Location string
param adminUsername string

@secure()
param adminPassword string
param subnetId string

resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: sqlServername
  location: Location
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: 'mkdatabase'
  location: Location
  properties: {
    catalogCollation: 'DATABASE_DEFAULT'
  }
}

resource sqlvnet 'Microsoft.Sql/servers/virtualNetworkRules@2024-05-01-preview' = {
  parent: sqlServer
  name: 'string'
  properties: {
    ignoreMissingVnetServiceEndpoint: true
    virtualNetworkSubnetId: subnetId
  }
}
