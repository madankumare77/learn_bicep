param logAnalyticsName string

param Location string

param workspacesku string = 'Free'

@description('Number of days to retain data.')
param retentionInDays int = 30

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: Location
  properties: {
    sku: {
      name: workspacesku
    }
    retentionInDays: retentionInDays
  }
}

output logAnalyticsId string = law.id
output logAnalyticsWorkspaceId string = law.properties.customerId

