param cosmosDbName string
param Location string
param secondaryLocation string
param failoverEnabled bool = true

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' = { 
  name: cosmosDbName
  location: Location
  properties: { 
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: { 
      defaultConsistencyLevel: 'Session'
    }
    enableAutomaticFailover: failoverEnabled
    locations: [
      {
        locationName: Location
        failoverPriority: 0
        isZoneRedundant: false
      }
      {
        locationName: secondaryLocation
        failoverPriority: 1
        isZoneRedundant: false
      }
    ]
  }
}
