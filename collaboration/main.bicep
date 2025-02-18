@description('The location into the resources deployed')
param location string = resourceGroup().location

@description('Selecte the env you want to provision')
@allowed([
  'production'
  'test'
])
param environmentType string

@maxLength(13)
param resourceNameSuffix string = uniqueString(resourceGroup().id)

@description('The adminisrartor login username')
param sqlserverAdministratorLogin string

@secure()
param sqlServerAdministratorLoginPassword string

@description('The tags to apply to each resources')
param tags object = {
  CostCenter: 'Marketing'
  DataClassification: 'Public'
  Owner: 'WebsiteTeam'
  Environment: 'Production'
}

//Define the name for resources.
var appServiceAppName = 'mkwebsite${resourceNameSuffix}'
var appServicePlanName = 'mkwebsite-plan'
var sqlServerName = 'mksqlserver${resourceNameSuffix}'
var sqlDatabaseName = 'mk-database'
var managedIdentityName = 'mk-managed-id'
var applicationInsightsName = 'mk-appinsights'
var storageAccountName = 'mkst001${resourceNameSuffix}'
var blobContainerNames = [
  'productspecs'
  'productmanuals'
]

@description('Define the skus for each components based on the env type')
var environmentConfigurationMap = {
  Production: {
    appServicePlan: {
      sku: {
        name: 'S1'
        capacity: 2
      }
    }
    storageAccount: {
      sku: {
        name: 'Standard_GRS'
      }
    }
    sqlDatabase: {
      sku: {
        name: 'S1'
        tier: 'Standard'
      }
    }
  }
  test: {
    appServicePlan: {
      sku: {
        name: 'F1'
        capacity: 2
      }
    }
    storageAccount: {
      sku: {
        name: 'Standard_LRS'
      }
    }
    sqlDatabase: {
      sku: {
        name: 'Basic'
      }
    }
  }
}

@description('The role definition ID of the built-in Azure \'Contributor\' role.')
var contributorRoleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'

resource sqlserver 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlserverAdministratorLogin
    administratorLoginPassword: sqlServerAdministratorLoginPassword
    version: '12.0'
  }
}

resource sqldatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlserver
  name: sqlDatabaseName
  location: location
  sku: environmentConfigurationMap[environmentType].sqlDatabase
  tags: tags
}

resource sqlfirewallRulesAllowAllAzureIPs 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: sqlserver
  name: 'AllowAllAzureIPs'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: environmentConfigurationMap[environmentType].appServicePlan
}

resource appServiceApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceAppName
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'StorageAccountConnectionString'
          value: storageAccountConnectionString
        }
      ]
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: environmentConfigurationMap[environmentType].storageAccount.sku
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }

  resource blobServices 'blobServices' existing = {
    name: 'default'
    resource container 'containers' = [for blobContainerName in blobContainerNames: {
      name: blobContainerName
    }]
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: managedIdentityName
  location: location
  tags: tags
}

@description('Grant the \'Contributor\' role to the user-assigned managed identity, at the scope of the resource group.')
resource roleassignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(contributorRoleDefinitionId, resourceGroup().id)

  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleDefinitionId)
    principalId: managedIdentity.properties.principalId
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}
