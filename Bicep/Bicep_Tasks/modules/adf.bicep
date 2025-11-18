param dataFactoryname string
param Location string
param lawId string

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = { 
  name: dataFactoryname
  location: Location
  identity: {
    type: 'SystemAssigned'
  }
}

resource diagnosticsetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${dataFactoryname}-diag'
  scope: dataFactory
  properties:{
    workspaceId: lawId
    logs:[
      { 
        category: 'PipelineRun'
        enabled: true
      }
    ]
    metrics: [ {
      enabled: true
      category: 'AllMetrics'
    }]
  }
}


output dataFactoryId string = dataFactory.id
output dataFactoryPrincipalId string = dataFactory.identity.principalId
