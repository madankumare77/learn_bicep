// 9. Create an Azure Migrate project using a Bicep template with the following requirements:
// •	Deploy an Azure Migrate project for assessment and migration purposes in the specified Azure region.
// •	Optionally create a Recovery Services Vault in the same region for storing replication and recovery data.
// •	Deploy an Azure Migrate appliance for discovering on-premises machines and enabling replication.
// •	Ensure that the project, appliance, and recovery vault are tagged appropriately for organizational purposes (e.g., 'Environment: Production', 'Department: IT').
// •	Output the IDs of the Azure Migrate project, Recovery Services Vault (if created), and the Azure Migrate appliance for future use or integration.
// Ensure the deployment is flexible with parameters like location, project name, appliance name, and Recovery Services Vault name (optional).

param location string = resourceGroup().location
param migrateProjectName string = 'migrateProject'
param migrateApplianceName string = 'migrateAppliance'
param recoveryVaultName string = ''
param tags object = {
  Environment: 'Production'
  Department: 'IT'
}

resource migrateProject 'Microsoft.Migrate/migrateProjects@2023-01-01' = { 
  name: migrateProjectName
  location: location
  properties: {}
  //eTag: 'string'
}

resource recoveryVault 'Microsoft.RecoveryServices/vaults@2024-10-01' = if (!empty(recoveryVaultName)) { 
  name: recoveryVaultName
  location: location
  properties: {}
  sku: {
    name: 'Standard'
  }
  tags: tags
}

resource migrateApplianc 'Microsoft.Migrate/migrateProjects/appliance@2023-01-01' = {
  parent: migrateProject
  name: migrateApplianceName
  properties: {
    discoverySolutionId: guid(migrateProject.id, migrateApplianceName)
  }
  tags: tags
}

output migrationprojectId string = migrateProject.id
output migrateAppliancId string = migrateApplianc.id
output recoveryVaultId string = recoveryVault.id
