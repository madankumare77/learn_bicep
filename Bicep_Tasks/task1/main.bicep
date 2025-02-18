//1. Design a Bicep template to create an Azure Key Vault in the Resource Group (RG-EY-India).
//The template should include parameters for configuring access policies and private endpoint requirements. 
//It should also integrate with a Log Analytics workspace. 
//set the Key Vault SKU to Standard, configure network ACLs to deny access, 
// and grant access policies for only 'Get' and 'List' secret permissions.

@description('Specifies the name of the key vault.')
param keyVaultName string = 'mk-kv-001'

@description('Specifies the Azure location where the key vault should be created.')
param location string = resourceGroup().location

@description('Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
param enabledForDiskEncryption bool = false

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledForTemplateDeployment bool = false

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
param keysPermissions array = [
  'list'
]

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
param secretsPermissions array = [
  'list'
  'Get'
]

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param objectId string

var vnetname = '${keyVaultName}-vnet'
var snet1    = '${keyVaultName}-snet1'

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    tenantId: tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    accessPolicies: [
      {
        objectId: objectId
        tenantId: tenantId
        permissions: {
          keys: keysPermissions
          secrets: secretsPermissions
        }
      }
    ]
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetname, snet1)
        }
      ]
    }
  }
}

// Creates a virtual network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetname
  location: location
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

output virtualNetworkid string = virtualNetwork.id
output virtualNetworkname string = virtualNetwork.name

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: '${keyVaultName}-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${keyVaultName}-pelink'
        properties: {
          groupIds: [
            'vault'
          ]
          privateLinkServiceId: kv.id
        }
      }
    ]
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetname, snet1)
    }
  }
}

@description('Name of the workspace.')
param workspaceName string = 'mk-workspace-001'

@description('Pricing tier: PerGB2018 or legacy tiers (Free, Standalone, PerNode, Standard or Premium) which are not available to all customers.')
@allowed([
  'pergb2018'
  'Free'
  'Standalone'
  'PerNode'
  'Standard'
  'Premium'
])
param sku string = 'Free'

@description('Number of days to retain data.')
param retentionInDays int = 30

@description('true to use resource or workspace permissions. false to require workspace permissions.')
param resourcePermissions bool = true

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: resourcePermissions
    }
  }
}

resource diagnosticsetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'kvdiagnostics'
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

output location string = location
output name string = kv.name
output resourceGroupName string = resourceGroup().name
output resourceId string = kv.id


//Connect-AzAccount
//Get-AzSubscription
//$context = Get-AzSubscription -SubscriptionId "a597e5fe-3c45-4412-b944-53e730b31c57"
//Set-AzContext $context
//Set-AzDefault -ResourceGroupName learn-74951398-ff02-4661-a985-638e1c219de6

//New-AzResourceGroupDeployment -TemplateFile main.bicep

//•	New-AzResourceGroupDeployment -WhatIf -TemplateFile main.bicep

// $upn = Read-Host -Prompt "Enter your email address used to sign in to Azure"
// (Get-AzADUser -UserPrincipalName $upn).Id
// Write-Host "Press [ENTER] to continue..."
