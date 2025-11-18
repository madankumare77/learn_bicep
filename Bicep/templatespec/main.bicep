@description('The Azure region into which the Cosmos DB resources should be deployed.')
param location string = resourceGroup().location

@description('The name of the Cosmos DB account. This name must be globally unique, and it must only include lowercase letters, numbers, and hyphens.')
@minLength(3)
@maxLength(44)
param cosmosDBAccountName string = 'mktoy-${uniqueString(resourceGroup().id)}'

@description('A descriptive name for the role definition.')
param roleDefinitionFriendlyName string = 'Read and Write'

@description('The list of actions that the role definition permits.')
param roleDefinitionDataActions array = [
  'Microsoft.DocumentDB/databaseAccounts/readMetadata'
  'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
]

@description('The object ID of the Azure AD principal that should be granted access using the role definition.')
param roleAssignmentPrincipalId string

var roleDefinitionName = guid('sql-role-definition', cosmosDBAccount.id)
var roleAssignmentName = guid('sql-role-assignment', cosmosDBAccount.id)

resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2021-04-15' = {
  name: cosmosDBAccountName
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    backupPolicy: {
      type: 'Continuous'
    }
  }
}

resource roleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-04-15' = {
  parent: cosmosDBAccount
  name: roleDefinitionName
  properties: {
    roleName: roleDefinitionFriendlyName
    type: 'CustomRole'
    assignableScopes: [
      cosmosDBAccount.id
    ]
    permissions: [
      {
        dataActions: roleDefinitionDataActions
      }
    ]
  }
}

resource roleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2021-04-15' = {
  parent: cosmosDBAccount
  name: roleAssignmentName
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: roleAssignmentPrincipalId
    scope: cosmosDBAccount.id
  }
}

//Connect-AzAccount
//Get-AzSubscription
//$context = Get-AzSubscription -SubscriptionId "a597e5fe-3c45-4412-b944-53e730b31c57"
//Set-AzContext $context
//Set-AzDefault -ResourceGroupName learn-74951398-ff02-4661-a985-638e1c219de6


//New-AzTemplateSpec -ResourceGroupName learn-74951398-ff02-4661-a985-638e1c219de6 -Name mkToyCosmosDBAccount -Location westus -DisplayName 'Cosmos DB account' -Description "This template spec creates a Cosmos DB account that meets our company's requirements." -Version '1.0' -TemplateFile main.bicep

//New-AzResourceGroupDeployment -TemplateSpecId /subscriptions/a597e5fe-3c45-4412-b944-53e730b31c57/resourceGroups/learn-74951398-ff02-4661-a985-638e1c219de6/providers/Microsoft.Resources/templateSpecs/mkToyCosmosDBAccount/versions/1.0

//New-AzTemplateSpec -ResourceGroupName learn-74951398-ff02-4661-a985-638e1c219de6 -Name mkToyCosmosDBAccount -Location westus -DisplayName 'Cosmos DB account' -Description "This template spec creates a Cosmos DB account that meets our company's requirements." -Version '2.0' -TemplateFile main.bicep

//$token = (Get-AzAccessToken -ResourceUrl "https://graph.windows.net/").Token

//$userObjectId = (Invoke-RestMethod -Uri 'https://graph.windows.net/me?api-version=1.6' -Headers @{ 'Authorization' = "Bearer $token"}).objectID

//New-AzResourceGroupDeployment -TemplateSpecId $templateSpecVersionResourceId -roleAssignmentPrincipalId $userObjectId
