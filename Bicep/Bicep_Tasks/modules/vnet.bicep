param vnetname string
param location string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetname
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'appsubnet'
        properties: {addressPrefix: '10.0.1.0/24'}
      }
      {
        name: 'sqlsubnet'
        properties: {addressPrefix: '10.0.1.0/24'}
      }
      {
        name: 'functionsubnet'
        properties: {addressPrefix: '10.0.1.0/24'}
      }
      {
        name: 'storagesubnet'
        properties: {addressPrefix: '10.0.1.0/24'}
      }
    ]
  }
}

resource appNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'appNSG'
  location: location
  properties: {
    securityRules: [
      { 
        name: 'Allowtraffic'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: ['80']
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

output vnetId string = virtualNetwork.id
output appsubnetId string = virtualNetwork.properties.subnets[0].id
output sqlsubnetId string = virtualNetwork.properties.subnets[1].id
output functionsubnetId string = virtualNetwork.properties.subnets[2].id
output storagesubnetId string = virtualNetwork.properties.subnets[3].id
