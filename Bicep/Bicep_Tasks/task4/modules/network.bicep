param ventname string
param Location string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: ventname
  location: Location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${ventname}-snet1'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

output subnetId string = virtualNetwork.properties.subnets[0].id
