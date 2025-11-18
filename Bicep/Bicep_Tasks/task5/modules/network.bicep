param ventname string
param Location string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: '${ventname}-vnet'
  location: Location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${ventname}-snet-frountend'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: '${ventname}-snet-backend'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

//Frountend NSG
resource frountendNSG 'Microsoft.Network/networkSecurityGroups@2024-05-01' = { 
  name: 'Frontend-NSG'
  location: Location
  properties: { 
    securityRules: [ 
      {
        name: 'Allow_Http'
        properties: { 
        priority:100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '80'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
      }
    }
    {
      name: 'Allow_RDP'
      properties: { 
      priority:110
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3389'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
    }
  }
  ]
}
}

//Backend NSG
resource backendNSG 'Microsoft.Network/networkSecurityGroups@2024-05-01' = { 
  name: 'Backend-NSG'
  location: Location
  properties: { 
    securityRules: [ 
      {
        name: 'Allow_SQL_From_Frountend'
        properties: { 
        priority:100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '1433'
        sourceAddressPrefix: '10.0.1.0/24'
        destinationAddressPrefix: '*'
      }
    }
    ]
  }
}

output virtualNetworkID string = virtualNetwork.id
output subnetId0 string = virtualNetwork.properties.subnets[0].id
output subnetId1 string = virtualNetwork.properties.subnets[1].id
