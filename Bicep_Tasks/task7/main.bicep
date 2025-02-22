// 7.task to create a Cosmos DB with primary and secondary locations 
// and configure auto-failover priority.  
// Additionally, set up an alert to notify when the database is deleted.

param Location string = resourceGroup().location
param secondaryLocation string = 'eastus'
param cosmosDbName string =  'mkcosmosdb'
param actionGroupId string

//Deploy Cosmos DB with failover config
module cosmosDb 'modules/cosmosdb.bicep' = { 
  name:'CosmosDbDeployment'
  params: { 
    cosmosDbName: cosmosDbName
    Location: Location
    secondaryLocation: secondaryLocation
  }
}

//Deploy Alerts for database
module alert 'modules/alerts.bicep' = { 
  name: 'alertDeployment'
  params: { 
    cosmosDbName: cosmosDbName
    Location: Location
    actionGroupId: actionGroupId
  }
}


//create an action group
//az monitor action-group create --resource-group 'rg name' --name 'actiongroupname' --short-name MkAg --action email 
