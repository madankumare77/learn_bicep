// 2. Create a Storage Account that meets below specifications.
// •	Specifies allowed types for the storage account (StorageV2, Blob Storage, File Storage).
// •	Restricts redundancy options to Standard_LRS and Standard_ZRS.
// •	Configures private endpoint access.
// •	Integrates with Log Analytics Workspace.
// •	Enables Blob Lifecycle Management to automatically delete blobs older than 365 days.

param StorageAccountName string

param Location string = resourceGroup().location

@allowed([
  'StorageV2'
  'BlobStorage'
  'FileStorage'
])
param storageKind string = 'StorageV2'

@allowed([
  'Standered_LRS'
  'Standered_ZRS'
])
param skuName string = 'Standered_LRS'
var vnetname = '${StorageAccountName}-vnet'
var snet1    = '${StorageAccountName}-snet1'

//Storage Account Resource
resource StorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: StorageAccountName
  location: Location
  kind: storageKind
  sku: {name: skuName}
  properties:{
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}


// Creates a virtual network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetname
  location: Location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: snet1
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      // {
      //   name: '${keyVaultName}-snet2'
      //   properties: {
      //     addressPrefix: '10.0.1.0/24'
      //   }
      // }
    ]
  }
}

//private endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${StorageAccountName}-pe'
  location: Location
  properties:{ 
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetname, snet1)
    }
    privateLinkServiceConnections: [
      { 
        name: '${StorageAccountName}-pe-connection'
        properties:{ 
          privateLinkServiceId: StorageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

//Diagnostic settings for Log Analytics
param workspacesku string = 'Free'

@description('Number of days to retain data.')
param retentionInDays int = 30

@description('true to use resource or workspace permissions. false to require workspace permissions.')
param resourcePermissions bool = true

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${StorageAccountName}-law'
  location: Location
  properties: {
    sku: {
      name: workspacesku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: resourcePermissions
    }
  }
}

resource diagnosticsetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${StorageAccountName}-diag'
  properties:{
    workspaceId: workspace.id
    logs:[
      {
        enabled: true
        category:'AuditEvent'
        retentionPolicy:{
          enabled:true
          days:retentionInDays
        }
      }
    ]
  }
}

//Blod Lifecycle management policy
resource lifecyclePolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2023-05-01' = { 
  parent: StorageAccount
  name: 'default'
  properties: { 
    policy: { 
      rules: [ {
        name: 'DeleteBlobOlderthan365d'
        enabled: true
        type: 'Lifecycle'
        definition: {
          actions: { 
            baseBlob: { 
              delete: {
                daysAfterModificationGreaterThan:365
              }
            }
          }
          filters:{blobTypes:['blockBlob']}
        }
      }]
    }
  }
}

