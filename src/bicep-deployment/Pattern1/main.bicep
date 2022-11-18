/*region Header
      =========================================================================================================
      Created by:       Author: Your Name | your.name@azurestream.io 
      Created on:       9/13/2022
      Description:      Pattern 1
      =========================================================================================================

      Dependencies:
        Install Azure CLI
        https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest 

        Install Latest version of Bicep
        https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install

      SCRIPT STEPS 
      1 - Create Managed VNet - (FOR PATTERN 1 WE WILL NOT DEPLOY A VNET - WE WILL LEAVE IT SIMPLE AND JUST OPEN UP SYNAPSE WORKSPACE TO PUBLIC ACCESS)
      2 - Create Storage Accounts
      3 - Create Azure SQL Server and DB
      4 - Create Key Vault
      5 - Create Synapse Workspace
      5 - Create Synapse Access Policy to get into Key Vault
      6 - Apply necessary RBAC
      7 - Create Synapse Workspace Assets (Linkd Services, Datasets, Pipelines, Notebooks, Triggers, etc. )
*/

//targetScope = 'subscription'

//********************************************************
// Workload Deployment Control Parameters
//********************************************************
param ctrlDeploySampleArtifacts bool = true         //Controls the creation of sample artifcats (SQL Scripts, Notebooks, Linked Services, Datasets, Dataflows, Pipelines) based on chosen template.

//********************************************************
// Global Parameters
//********************************************************
param utcValue string = utcNow()

@description('Unique Prefix')
param prefix string = 'ftatoolkit'

@description('Unique Suffix')
//param uniqueSuffix string = substring(uniqueString(resourceGroup().id),0,3)
param uniqueSuffix string = substring(toLower(replace(uniqueString(subscription().id, resourceGroup().id, utcValue), '-', '')), 1, 3) 

@description('Resource Location')
param resourceLocation string = resourceGroup().location

@allowed([
  'OpenDatasets'
])
param sampleArtifactCollectionName string = 'OpenDatasets'

@allowed([
  'default'
  'vNet'
])
@description('Network Isolation Mode')
param networkIsolationMode string = 'default'

param env string = 'Dev'

param tags object = {
  Owner: 'ftatoolkit'
  Project: 'ftatoolkit'
  Environment: env
  Toolkit: 'bicep'
  Name: prefix
}

//********************************************************
// Resource Config Parameters
//********************************************************
//vNet Module Parameters
//----------------------------------------------------------------------


//Storage Account Module Parameters - Data Lake Storage Account for Synapse Workspace
@description('Storage Account Type')
param storageAccountType string
var storageAccountName = '${prefix}adls${uniqueSuffix}'

//----------------------------------------------------------------------

//Key Vault Module Parameters
@description('Key Vault Account Name')
param keyVaultName string = '${prefix}-keyvault-${uniqueSuffix}' 

@description('Your Service Principal Object ID')
param spObjectId string //This is your Service Principal Object ID

//----------------------------------------------------------------------

//Synapse Module Parameters
var synapseWorkspaceName = '${prefix}-synapse-${uniqueSuffix}'

@description('Managed resource group is a container that holds ancillary resources created by Azure Synapse Analytics for your workspace. By default, a managed resource group is created for you when your workspace is created. Optionally, you can specify the name of the resource group that will be created by Azure Synapse Analytics to satisfy your organization’s resource group name policies.')
param synapseManagedResourceGroup string

@description('Provide the user name for SQL login.')
param sqlAdministratorLogin string

@secure()
@description('The passwords must meet the following guidelines:<ul><li> The password does not contain the account name of the user.</li><li> The password is at least eight characters long.</li><li> The password contains characters from three of the following four categories:</li><ul><li>Latin uppercase letters (A through Z)</li><li>Latin lowercase letters (a through z)</li><li>Base 10 digits (0 through 9)</li><li>Non-alphanumeric characters such as: exclamation point (!), dollar sign ($), number sign (#), or percent (%).</li></ul></ul> Passwords can be up to 128 characters long. Use passwords that are as long and complex as possible. Visit <a href=https://aka.ms/azuresqlserverpasswordpolicy>aka.ms/azuresqlserverpasswordpolicy</a> for more details.')
param sqlAdministratorLoginPassword string
//----------------------------------------------------------------------

//********************************************************
// Variables
//********************************************************

var deploymentScriptUAMIName = toLower('${prefix}-uami')

//********************************************************
// Deploy Core Platform Services 
//********************************************************

//1. Deploy Required VNet
//N/A for Pattern 1

//2. Deploy Required Storage Account(s)
//Deploy Storage Accounts (Create your Storage Account (ADLS Gen2 & HNS Enabled) for your Synapse Workspace)
module m_storage 'modules/deploy_2_storage.bicep' = {
  name: 'deploy_storage'
  params: {
    resourceLocation: resourceLocation
    storageAccountName: storageAccountName
    storageAccountContainer: toLower('${prefix}-synapse')
    storageAccountType: storageAccountType
  }
}

//3. Deploy Azure SQL Server(s) and Sample DB
module m_sqlsvr 'modules/deploy_3_sqlserver.bicep' = {
  name: 'deploy_sqlserver'
  params: {
    resourceLocation: resourceLocation
    sqlservername: toLower('${prefix}-sql-${uniqueSuffix}') 
    tags: tags
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    databaseName: 'ftatoolkitsampledb'
  }
}

//4. Deploy Required Key Vault
module m_keyvault 'modules/deploy_4_keyvault.bicep' = {
  name: 'deploy_keyvault'
  params: {
    resourceLocation: resourceLocation
    keyVaultName: keyVaultName
    deploymentScriptUAMIName: deploymentScriptUAMIName

    //Send in Service Principal and/or User Oject ID
    spObjectId: spObjectId

    //Send in Storage Account Key and Cnx
    storageAccountKey: m_storage.outputs.storageAccountKey
    storageAccountCnx: m_storage.outputs.storageAccountCnx

    //Send in SQL Server and DB Secrets
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword : sqlAdministratorLoginPassword
    sqlServerName: m_sqlsvr.outputs.sqlServerNameDomainName
    sqlServerDBName: m_sqlsvr.outputs.sqlserverDBName
    sqlCnxString: 'Server=tcp:${m_sqlsvr.outputs.sqlServerNameDomainName},1433;Initial Catalog=${m_sqlsvr.outputs.sqlserverDBName};Persist Security Info=False;User ID=${sqlAdministratorLogin};Password=${sqlAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
  dependsOn: [
    m_storage
    m_sqlsvr 
  ]
}

//5.a Deploy Synapse Workspace
module m_synapse 'modules/deploy_5a_synapse.bicep' = {
  name: 'deploy_synapse'
  params: {
    resourceLocation: resourceLocation
    synapseWorkspaceName: toLower(synapseWorkspaceName)
    managedResourceGroupName: synapseManagedResourceGroup

    networkIsolationMode: networkIsolationMode
    tags: tags

    defaultDataLakeStorageAccountName: storageAccountName
    defaultDataLakeStorageFileSystemName: toLower('${prefix}-synapse')
    
    //Send in SQL Pool Parameters
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
  }
  dependsOn: [
    m_storage
  ]
}

//5.b Deploy Key Vault Access Policy for Synapse
module m_KeyVaultSynapseAccessPolicy 'modules/deploy_5b_keyvaultsynapseaccesspolicy.bicep' = {
  name: 'deploy_KeyVaultSynapseAccessPolicy'
  params: {
    keyVaultName: keyVaultName
    synapseManagedIdentityId: m_synapse.outputs.synapseManagedIdentityId
  }
  dependsOn: [
    m_synapse
  ]
}

//********************************************************
// RBAC Role Assignments
//********************************************************

module m_RBACRoleAssignment 'modules/deploy_6_RBAC.bicep' = {
  name: 'deploy_RBAC'
  params: {
    dataLakeAccountName: storageAccountName
    synapseWorkspaceName: m_synapse.outputs.synapseWorkspaceName
    synapseManagedIdentityId: m_synapse.outputs.synapseManagedIdentityId
    UAMIPrincipalID: m_keyvault.outputs.deploymentScriptUAMIPrincipalId
  }
  dependsOn:[
    m_synapse
  ]
}

//********************************************************
// Post Deployment Scripts
//********************************************************
var synapseWorkspaceParams = '-SynapseWorkspaceName ${synapseWorkspaceName} -SynapseWorkspaceID ${m_synapse.outputs.synapseWorkspaceID}' //(i.e. -SynapseWorkspaceName ftatoolkit-synapse-xxx -SynapseWorkspaceID /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/P1-AnalyticsFundamentals-RG/providers/Microsoft.Synapse/workspaces/ftatoolkit-synapse-xxx)
var datalakeAccountSynapseParams = '-DataLakeAccountName ${storageAccountName} -DataLakeAccountResourceID ${m_storage.outputs.storageAccounResourceId}' //(i.e. -DataLakeAccountName ftatoolkitadlsxxx -DataLakeAccountResourceID /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/P1-AnalyticsFundamentals-RG/providers/Microsoft.Storage/storageAccounts/ftatoolkitadlsxxx)
var keyVaultParams = '-KeyVaultName ${keyVaultName} -KeyVaultID ${m_keyvault.outputs.keyVaultID}' //(i.e. -KeyVaultName ftatoolkit-keyvault-xxx -KeyVaultID /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/P1-AnalyticsFundamentals-RG/providers/Microsoft.KeyVault/vaults/ftatoolkit-keyvault-xxx)
var sqlParams = '-AzureSQLServerName ${m_sqlsvr.outputs.sqlServerName}' //(i.e. -AzureSQLServerName ftatoolkit-sql-xxx)
var uamiParams = '-UAMIPrincipalID ${m_keyvault.outputs.deploymentScriptUAMIPrincipalId}' //(i.e. -UAMIPrincipalID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)

var sampleArtifactsParams = ctrlDeploySampleArtifacts ? '-CtrlDeploySampleArtifacts $True -SampleArtifactCollectioName ${sampleArtifactCollectionName}' : ''

var synapseScriptArguments = '-SubscriptionID ${subscription().subscriptionId} -ResourceGroupName ${resourceGroup().name} -ResourceGroupLocation ${resourceLocation} ${synapseWorkspaceParams} ${datalakeAccountSynapseParams} ${keyVaultParams} ${sqlParams} ${uamiParams} ${sampleArtifactsParams}' 

module m_PostDeploymentScripts 'modules/deploy_7_Artifacts.bicep' = {
  name: 'PostDeploymentScript'
  dependsOn: [
      m_RBACRoleAssignment
  ]
  params: {
    deploymentDatetime: utcValue
    deploymentScriptUAMIResourceId: m_keyvault.outputs.deploymentScriptUAMIResourceId
    resourceLocation: resourceLocation
    synapseScriptArguments: synapseScriptArguments
  }
}
