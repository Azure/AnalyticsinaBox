targetScope = 'subscription'

param location string = 'westus'
param prefix string
param postfix string
param env string = 'dev'
@secure()
param sqladministratorLoginPassword string

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

