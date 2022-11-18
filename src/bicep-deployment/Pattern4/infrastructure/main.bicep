targetScope = 'subscription'

param location string = 'westus2'
param prefix string
param postfix string
param env string 
param objectID string
param sqladministratorLoginPassword string
// param synapsedatalakegen2name string
// param synapsedatalakegen2filesystemname string


//variables
var subscriptionId = subscription().subscriptionId
var rdPrefix = '/subscriptions/${subscriptionId}/providers/Microsoft.Authorization/roleDefinitions'
var role = {
  Owner: '${rdPrefix}/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: '${rdPrefix}/b24988ac-6180-42a0-ab88-20f7382dd24c'
  StorageBlobDataReader: '${rdPrefix}/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
  StorageBlobDataContributor: '${rdPrefix}/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}
var sqladministratorLogin='rootuser'

param tags object = {
  Owner: 'fasthack'
  Project: 'fasthack'
  Environment: env
  Toolkit: 'bicep'
  Name: prefix
}

var baseName  = '${prefix}${postfix}${env}'
var resourceGroupName = 'P4-${baseName}-RG'
var sqlServerName = '${prefix}-sql-${postfix}-${env}'
var synapseWorkSpaceName = '${prefix}-synapse-${postfix}-${env}'
var dataLakeg2SynapseName = '${prefix}adlssyn${postfix}${env}'
var storageAccountName = '${prefix}st${postfix}${env}'
var datalakeName = '${prefix}adl${postfix}${env}'
var keyVaultName = '${prefix}-akv-${postfix}-${env}'

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourceGroupName
  location: location

  tags: tags
}


//sql server

module sqlsvr './modules/deploy_1_sqlserver.bicep' = {
  name: 'sqlsvr'
  scope: resourceGroup(rg.name)
  params: {
    name: sqlServerName
    location: location
    tags: tags
    administratorLogin: sqladministratorLogin
    administratorLoginPassword: sqladministratorLoginPassword
    databaseName: 'sampledb'

  }
}


// synapse workspace

module synapse './modules/deploy_2_synapse.bicep' = {
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
    sparkPoolName: 'sparkpool'
    sparkPollNodeSize: 'small'
    sparkPoolMinNodeCount: 3
    sparkPoolMaxNodeCount: 3
  }
}


// Storage Account
module st './modules/deploy_3_storage_account.bicep' = {
  name: 'st'
  scope: resourceGroup(rg.name)
  params: {
    name: storageAccountName
    location: location
    tags: tags
    roleAssignmentPrincipalID : synapse.outputs.synapsemanageidentity
    roleAssignmnetPrincipalType : 'ServicePrincipal'
    roleDefinitionId :  role['StorageBlobDataContributor']
  }
  dependsOn: [
    synapse    
  ]
}

// data lake

module dl './modules/deploy_4_datalake_account.bicep' = {
  name: 'dl'
  scope: resourceGroup(rg.name)
  params: {
    name: datalakeName
    location: location
    tags: tags
    roleAssignmentPrincipalID : synapse.outputs.synapsemanageidentity
    roleAssignmnetPrincipalType : 'ServicePrincipal'
    roleDefinitionId :  role['StorageBlobDataContributor']
  }
  dependsOn: [
    synapse    
  ]
  
}



// key vault  and secret creation

module kv './modules/deploy_5_key_vault.bicep' = {
  name: 'kv'
  scope: resourceGroup(rg.name)
  params: {
    name: keyVaultName
    location: location
    tags: tags
    objectID: objectID
    synapseManageIdentity: synapse.outputs.synapsemanageidentity
    administratorLoginPassword : sqladministratorLoginPassword
    administratorLogin: sqladministratorLogin
    sqlservername: sqlsvr.outputs.sqlservername
    sqlserverDBName: sqlsvr.outputs.sqlserverDBName
    sqlconnectionstring: 'Server=tcp:${sqlsvr.outputs.sqlservername},1433;Initial Catalog=${sqlsvr.outputs.sqlserverDBName};Persist Security Info=False;User ID=${sqladministratorLogin};Password=${sqladministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
  dependsOn:[
    synapse
    sqlsvr
  ]
}
