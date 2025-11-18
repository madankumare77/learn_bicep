//private endpoint
param Location string
param peName string
param subnetId string
param privateLinkServiceId string
param groupIds array

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${peName}-pe'
  location: Location
  properties:{ 
    subnet: {
      id: subnetId //virtualNetwor.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      { 
        name: '${peName}-pe-connection'
        properties:{ 
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
}
