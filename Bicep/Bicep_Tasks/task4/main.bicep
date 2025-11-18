// 4.Create an Azure Load Balancer within a dedicated virtual network and subnet 
// and integrate it with a Log Analytics workspace. Implement this configuration in a module format.

param Location string = resourceGroup().location
param vnetName string = 'mkvnet'
param lbname string =  'mkloadbalencer'
param logAnalyticsName string = 'mk-law'

//Virtual Network
module network 'modules/network.bicep' = { 
  name: 'NetworDeployment'
  params: { 
    ventname: vnetName
    Location: Location
  }
}

//Deploy Log Analytics Workspace
module LogAnalytics 'modules/law.bicep' = { 
  name: 'LogAnalyticsDeployment'
  params: { 
    logAnalyticsName: logAnalyticsName
    Location: Location
  }
}

//Deploy Load Balancer with Law integration
module LoadBalancer 'modules/lb.bicep' = { 
  name: 'lbdeployment'
  params: { 
    lbname: lbname
    Location: Location
    lawId: LogAnalytics.outputs.logAnalyticsId
  }
}
