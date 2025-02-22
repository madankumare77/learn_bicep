param lbname string

param Location string

//param subnetId string

param lawId string

resource publicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = { 
  name: '${lbname}-publicIP'
  location: Location
  sku: { 
    name: 'Standard'
  }
  properties: { 
    publicIPAllocationMethod: 'Static'
  }
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2024-05-01' = { 
  name: lbname
  location: Location
  properties: {
    frontendIPConfigurations: [
      { 
        name: 'frontendconfig'
        properties: { 
          publicIPAddress: { 
            id: publicIP.id
          }
        }
      }
    ]
    backendAddressPools: [ {
      name: 'backendpool'
    }]
  }
}

resource diagnosticsetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${lbname}-diag'
  properties:{
    workspaceId: lawId
    logs:[
      { 
        category: 'LoadBalancerprobeHealthStatus'
        enabled: true
      }
      { 
        category: 'LoadBalancerAlertEvent'
        enabled: true
      }
      { 
        category: 'LoadBalancerFloLog'
        enabled: true
      }
    ]
  }
  scope: loadBalancer
}
