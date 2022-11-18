/*region Header
      Module Steps 
      1 - Assign Owner Role to UAMI to the Synapse Workspace
      2 - Assign Owner Role to UAMI to the Resource Group
      3 - Assign Storage Blob Data Contributor Role to Synapse Workspace
      4 - Assign Workspace Administrator  
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param dataLakeAccountName string
param synapseWorkspaceName string
param synapseManagedIdentityId string
param UAMIPrincipalID string

var azureRBACStorageBlobDataContributorRoleID = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Storage Blob Data Contributor Role: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
var azureRBACOwnerRoleID = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' //Owner: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner

//Reference existing resources for permission assignment scope
resource r_dataLakeStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: dataLakeAccountName
}

resource r_synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' existing = {
  name: synapseWorkspaceName
}

//Create Resources----------------------------------------------------------------------------------------------------------------------------

//https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments
//https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions
//1. Assign Owner Role to UAMI in the Synapse Workspace. UAMI needs to be Owner so it can assign itself as Synapse Admin and create resources in the Data Plane.
resource r_synapseWorkspaceOwner 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceId('Microsoft.Storage/storageAccounts', synapseWorkspaceName), UAMIPrincipalID)
  scope: r_synapseWorkspace
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACOwnerRoleID)
    principalId: UAMIPrincipalID
    principalType:'ServicePrincipal'
  }
}

//2. Deployment script UAMI is set as Resource Group owner so it can have authorization to perform post deployment tasks
resource r_deploymentScriptUAMIRGOwner 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceId('Microsoft.Storage/storageAccounts', synapseWorkspaceName), resourceGroup().id)
  scope: resourceGroup()
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACOwnerRoleID)
    principalId: UAMIPrincipalID
    principalType:'ServicePrincipal'
  }
}

//3. Assign Storage Blob Data Contributor Role to Synapse Workspace in the Raw Data Lake Account as per https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions#grant-the-managed-identity-permissions-to-adls-gen2-storage-account
//Create and apply RBAC to your synapse managed identity to the synapse adls storage account -Synapse Workspace Role Assignment as Blob Data Contributor Role in the Data Lake Storage Account
resource r_synapseWorkspacetorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceId('Microsoft.Storage/storageAccounts', synapseWorkspaceName), r_dataLakeStorageAccount.name)
  scope: r_dataLakeStorageAccount
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataContributorRoleID)
    principalId: synapseManagedIdentityId
    principalType:'ServicePrincipal'
  }
}

//https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-manage-synapse-rbac-role-assignments
//https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/administrators
//4. Make the User Assigned Managed Identity a Synapse Administrator
resource r_spObjectId_workspace_admin 'Microsoft.Synapse/workspaces/administrators@2021-06-01' = {
  name: 'activeDirectory'
  parent: r_synapseWorkspace
  properties: {
    administratorType: 'ActiveDirectory'
    sid: UAMIPrincipalID
    tenantId: subscription().tenantId
  }
}
