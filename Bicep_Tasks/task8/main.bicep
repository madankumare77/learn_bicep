// 8. Create a production-grade Azure Kubernetes Service (AKS) cluster using a Bicep template, ensuring it meets all production standards, including the following:
// •	Set up a dedicated virtual network and subnet for the AKS cluster with proper network segmentation.
// •	Configure network policies to ensure secure communication between AKS nodes and other resources.
// •	Integrate the AKS cluster with a SQL Database hosted in a dedicated network.
// •	Implement network monitoring and set up alerts for critical network performance and security events.
// •	Enable auto-scaling, logging, and monitoring of the AKS cluster.
// •	Ensure proper security measures are applied, such as role-based access control (RBAC), Azure Active Directory integration, and network security groups (NSGs).


param location string = resourceGroup().location
param aksClusterName string = 'mk-aks01'
param vnetName string = 'mkvnet'
param sqlServerName string = 'mk-sql01'
param aksNodeCount int = 3

//create Vnet
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    // subnets: [
    //   {
    //     name: '${vnetName}-snet'
    //     properties: {
    //       addressPrefix: '10.0.0.0/24'
    //     }
    //   }
    // ]
  }
}

//snet for aks
resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: '${aksClusterName}-snet'
  parent: virtualNetwork
  properties: {
    addressPrefix: '10.0.1.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

//snet for sql
resource sqlSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: '${sqlServerName}-snet'
  parent: virtualNetwork
  properties: {
    addressPrefix: '10.0.2.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

//Deploy AKS
resource aks 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: aksClusterName
  location: location
  properties: {
    dnsPrefix: aksClusterName
    kubernetesVersion: '1.26.3'
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'calico'
      serviceCidr: '10.0.3.0/24'
      dnsServiceIP: '10.0.3.10'
    }
    agentPoolProfiles: [
      { 
        name: 'nodepool1'
        count: aksNodeCount
        vmSize: 'Standard_D4s_v3'
        mode: 'System'
        vnetSubnetID: aksSubnet.id
        enableAutoScaling: true
        minCount: 2
        maxCount: 4
      }
    ]
  }
  identity: {
    type: 'SystemAssigned'
  }
}

//create sql server
param adminUsername string = 'sqladmin'

@secure()
param adminPassword string

resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: '${sqlServerName}-database'
  location: location
  properties: {
    catalogCollation: 'DATABASE_DEFAULT'
  }
  sku: { 
    name: 'S1'
    tier: 'Standerd'
  }
}

//pr for sql database
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${sqlServerName}-pe'
  location: location
  properties:{ 
    subnet: {
      id: sqlSubnet.id //virtualNetwor.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      { 
        name: '${sqlServerName}-pe-connection'
        properties:{ 
          privateLinkServiceId: sqlServer.id
          groupIds: ['sqlserver']
        }
      }
    ]
  }
}

//Law for aks
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${aksClusterName}-law'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

//Diagnostic logging for aks
resource diagnosticsetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${aksClusterName}-diag'
  scope: aks
  properties:{
    workspaceId: law.id
    logs:[
      { 
        category: 'kube-apiserver'
        enabled: true
      }
    ]
    metrics: [ {
      enabled: true
      category: 'AllMetrics'
    }]
  }
}

//Alters for network issue
resource aksAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${aksClusterName}-alerts'
  location: location
  properties: { 
    severity: 2
    enabled: true
    scopes: [aks.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: '1st criterion'
          metricName: 'aksmetrics'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: []
  }
}

//Assign role for aks to law
var contributorRoleDefinitionId = '749f88d5-cbae-40b8-bcfc-e573ddc772fa'
resource akslawRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aks.id, 'Monitoring Contributor')
  scope: law
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleDefinitionId)
    principalId: aks.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

