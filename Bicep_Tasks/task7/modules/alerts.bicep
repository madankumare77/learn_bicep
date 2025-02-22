param cosmosDbName string
param Location string
//param actionGroupName string
param actionGroupId string

resource metricAlerts 'Microsoft.Insights/metricAlerts@2018-03-01' = { 
  name: '${cosmosDbName}-alerts'
  location: Location
  properties: { 
    description: 'an alert to notify when the database is deleted'
    severity: 2
    enabled: true
    scopes: [ 
      subscription().id
    ]
    criteria: { 
      odata: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'string'
          metricName: 'Requests'
          metricNamespace: 'Microsoft.DocumentDB/databaseAccounts'
          operator: 'LessThan'
          threshold: 1
          aggregation: 'Total'
          dimensions: [
            {
              name: 'DatabaseAccountname'
              operator: 'Include'
              values: [ cosmosDbName ]
            }
          ]
        }
      ]
    }
    actions: [ {
      actionGroupId: actionGroupId
    }]
  }
}

// resource metricAlerts 'Microsoft.Insights/metricAlerts@2018-03-01' = { 
//   name: '${cosmosDbName}-alerts'
//   location: Location
//   properties: { 
//     description: 'an alert to notify when the database is deleted'
//     severity: 2
//     enabled: true
//     scopes: [ 
//       subscription().id
//     ]
//     criteria: {
//       allOf: [
//         {
//           dimensions: [
//             {
//               name: 'string'
//               operator: 'string'
//               values: [
//                 'string'
//               ]
//             }
//           ]
//           metricName: 'string'
//           metricNamespace: 'string'
//           name: 'string'
//           skipMetricValidation: bool
//           timeAggregation: 'string'
//           criterionType: 'string'
//           // For remaining properties, see MultiMetricCriteria objects
//         }
//       ]
//       odata: 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
//     }
//     actions: [ {
//       actionGroupId: actionGroupId
//     }]
//   }
// }
