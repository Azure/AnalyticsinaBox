targetScope = 'subscription'

param location string = 'westus'
@description('Prefix to resource name needed for uniqueness')
param prefix string
@description('Suffix to resource name needed for uniqueness')
param postfix string
param env string = 'dev'
@secure()
param sqladministratorLoginPassword string
@description('Pass in the Object ID of the AAD User or Service Principal that will own the KeyVault')
param objectIDUser string // this is needed for keyvault - pass in the object id of the AAD user
param objectIDDevOps string // this is needed for keyvault - pass in the object id of the AAD user
param userPrincipalSQLAdmin string

//variables

var sqladministratorLogin='rootuser'


param tags object = {
  Owner: 'fasthack'
  Project: 'fasthack'
  Environment: env
  Toolkit: 'bicep'
  Name: prefix
}

var baseName  = '${prefix}${postfix}${env}'
var resourceGroupName = 'P5-${baseName}-RG'
var sqlServerName = '${prefix}-sqlsrc-${postfix}-${env}'
var synapseWorkSpaceName = '${prefix}-synapse-${postfix}-${env}'
var dataLakeg2SynapseName = '${prefix}adlssyn${postfix}${env}'
var storageAccountName = '${prefix}wwibacpac${postfix}${env}'
var keyVaultName = '${prefix}-akv-${postfix}-${env}'

var subscriptionId = subscription().subscriptionId
var rdPrefix = '/subscriptions/${subscriptionId}/providers/Microsoft.Authorization/roleDefinitions'
var role = {
  Owner: '${rdPrefix}/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: '${rdPrefix}/b24988ac-6180-42a0-ab88-20f7382dd24c'
  StorageBlobDataReader: '${rdPrefix}/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
  StorageBlobDataContributor: '${rdPrefix}/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourceGroupName
  location: location

  tags: tags
}

//sql server for source DB and metadata database

module sqlsvr './modules/sqlserversourceandmetadata.bicep' = {
  name: 'sqlsvr'
  scope: resourceGroup(rg.name)
  params: {
    serverName: sqlServerName
    location: location
    tags: tags
    administratorLogin: sqladministratorLogin
    administratorLoginPassword: sqladministratorLoginPassword
    databaseNameWWI: 'WideWorldImporters'
    databaseNameMetadata: 'SynapseMetadataOrchestration'
    objectID: objectIDUser
    userPrincipalSQLAdmin: userPrincipalSQLAdmin
  }
}

// synapse workspace and default storage

module synapse './modules/synapseworkspace.bicep' = {
  name: 'synapse'
  scope: resourceGroup(rg.name)
  params: {
    synapseName: synapseWorkSpaceName
    location: location
    tags: tags
    administratorLogin: sqladministratorLogin
    administratorLoginPassword: sqladministratorLoginPassword
    datalakegen2name: dataLakeg2SynapseName
    defaultDataLakeStorageFilesystemName: 'root'
    dataLakeUrlFormat: 'https://{0}.dfs.core.windows.net'
    }
}

// Storage Account for WWI bacpac
module st './modules/storageAccountForWWIbacpac.bicep' = {
  name: 'st'
  scope: resourceGroup(rg.name)
  params: {
    name: storageAccountName
    location: location
    tags: tags
    roleAssignmentPrincipalID : objectIDDevOps
    roleAssignmnetPrincipalType : 'ServicePrincipal'
    roleDefinitionId :  role['StorageBlobDataContributor']
  }
 }


// key vault  and secret creation
// key vault needed for SQL connections strings to run SQL scripts to create and load tables from deployments pipelines

module kv './modules/keyvault.bicep' = {
  name: 'kv'
  scope: resourceGroup(rg.name)
  params: {
    name: keyVaultName
    location: location
    tags: tags
    objectIDUser: objectIDUser
    objectIDDevOps: objectIDDevOps
    synapseManageIdentity: synapse.outputs.synapsemanageidentity
    administratorLoginPassword : sqladministratorLoginPassword
    administratorLogin: sqladministratorLogin
    sqlservername: sqlsvr.outputs.sqlservername
    sqlserverDBNameWWI: sqlsvr.outputs.sqlserverDBNameWWI
    sqlconnectionstringWWI: 'Server=tcp:${sqlsvr.outputs.sqlservername},1433;Initial Catalog=${sqlsvr.outputs.sqlserverDBNameWWI};Persist Security Info=False;User ID=${sqladministratorLogin};Password=${sqladministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
    sqlserverDBNameMetadata: sqlsvr.outputs.sqlserverDBNameMetadata
    sqlconnectionstringMetadata: 'Server=tcp:${sqlsvr.outputs.sqlservername},1433;Initial Catalog=${sqlsvr.outputs.sqlserverDBNameMetadata};Persist Security Info=False;User ID=${sqladministratorLogin};Password=${sqladministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
    }
  dependsOn:[
    synapse
    sqlsvr
  ]
}

/* module linkedServices './modules/linkedServices.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'linkedServices'
  params: {
    sqlserverDBMetadata: sqlsvr.outputs.sqlserverDBNameMetadata
    sqlserverFQDN: sqlsvr.outputs.sqlserverFQDN
    workspaceName: synapseWorkSpaceName
   // workspaceId: synapse.outputs.synapseWorkspaceID
  }
}
*/

