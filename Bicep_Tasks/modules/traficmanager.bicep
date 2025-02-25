param location string
param tmName string

resource trafficManager 'Microsoft.Network/trafficmanagerprofiles@2022-04-01' = {
  name: '${tmName}-tm'
  location: location
  properties: {
    dnsConfig: {
      relativeName: 'mktm'
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTPS'
      port: 443
      path: '/any'
    }
    trafficRoutingMethod: 'Priority'
    endpoints: [
      { 
        name: 'production'
        type: 'Microsoft.Network/trafficmanagerprofiles/endpoints'
        properties: {
          target: 'prodappname.azurewebsites.net'
          priority:1
        }
      }
      { 
        name: 'staging'
        type: 'Microsoft.Network/trafficmanagerprofiles/endpoints'
        properties: {
          target: 'stagingappname.azurewebsites.net'
          priority:2
        }
      }
    ]
  }
}
