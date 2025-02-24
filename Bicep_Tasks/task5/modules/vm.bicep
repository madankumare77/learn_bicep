param vmName string
param Location string
param adminUsername string

@secure()
param adminPassword string

param subnetId string

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = { 
  name: vmName
  location: Location
  properties: { 
    hardwareProfile: {
      vmSize: 'Basic_A0'
    }
    osProfile: {
      computerName: vmName
      adminPassword: adminPassword
      adminUsername: adminUsername
    } 
    storageProfile: {
      imageReference: {
        publisher: 'Windows'
        offer: 'WindowsServer'
        sku: '2019-Datacenter-smalldisk'
        version: 'latest'
      }
      osDisk: { 
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        { 
          id: nic.id
        }
      ]
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: '${vmName}-nic'
  location: Location
  properties: {
    ipConfigurations: [
      { 
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

output vmName string = vm.name
