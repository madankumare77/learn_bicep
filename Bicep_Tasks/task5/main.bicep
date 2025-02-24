// 5. Create a simple application architecture using a Bicep template, including the following resources:
// •	Deploy a virtual machine with an inbuilt IIS server in the Frontend subnet, ensuring the necessary NSG rules are applied.
// •	Deploy a SQL Server in the Backend subnet, with communication allowed only through the Frontend subnet's NSG rules.
// •	Create a Log Analytics workspace to capture logs from both the virtual machine and SQL Server.


param vmName string = 'mkvm01'
param Location string = resourceGroup().location
param adminUsername string =  'mkuser01'

@secure()
param adminPassword string

module network 'modules/network.bicep' = {
  name: 'networkDeployment'
  params: {
    ventname: vmName
    Location: Location
  }
}

module vm 'modules/vm.bicep' = {
  name: 'vmDeployment'
  params: {
    vmName: vmName
    Location: Location
    subnetId: network.outputs.subnetId0
    adminPassword: adminPassword
    adminUsername: adminUsername
  }
}

module sql 'modules/sql.bicep' = {
  name: 'sqlDeployment'
  params: {
    sqlServername: 'mysqlserver'
    Location: Location
    adminPassword: adminPassword
    adminUsername: adminUsername
    subnetId: network.outputs.subnetId1
  }
}
