// 6. task to configure Azure Data Factory within a dedicated private subnet. 
// Ensure the Data Factory uses a system-assigned identity, 
// enables integration with a Log Analytics workspace and 
// configures diagnostic settings for monitoring and logging. 


param Location string = resourceGroup().location
param vnetName string = 'mkvnet'
param dataFactoryname string =  'mkdatafactory'
param logAnalyticsName string = 'mk-law'

var newVariable = '749f88d5-cbae-40b8-bcfc-e573ddc772fa'
var contributorRoleDefinitionId = newVariable


//Virtual Network
module network '../modules/network.bicep' = { 
  name: 'NetworDeployment'
  params: { 
    ventname: vnetName
    Location: Location
  }
}

//Deploy Log Analytics Workspace
module LogAnalytics '../modules/law.bicep' = { 
  name: 'LogAnalyticsDeployment'
  params: { 
    logAnalyticsName: logAnalyticsName
    Location: Location
  }
}

//pe
module pe '../modules/pe.bicep' = { 
  name: 'peDeployment'
  params: {
    peName: dataFactoryname
    Location: Location
    subnetId: network.outputs.subnetId
    privateLinkServiceId: adf.outputs.dataFactoryId
    groupIds: [
      'dataFactory'
    ]
  }
}

module adf '../modules/adf.bicep' = {
  name: 'ADF-Deployment'
  params: {
    dataFactoryname: dataFactoryname
    Location: Location
    lawId: LogAnalytics.outputs.logAnalyticsId
  }
}

resource lawRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: 'Monitoring Contributor'
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleDefinitionId)
    principalId: adf.outputs.dataFactoryPrincipalId
    principalType: 'ServicePrincipal'
  }
}
