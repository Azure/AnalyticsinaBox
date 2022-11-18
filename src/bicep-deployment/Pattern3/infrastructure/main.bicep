targetScope = 'subscription'

param location string = 'westus2'
param prefix string
param postfix string
param env string 
param objectID string
param sqladministratorLoginPassword string


//variables
var subscriptionId = subscription().subscriptionId
var rdPrefix = '/subscriptions/${subscriptionId}/providers/Microsoft.Authorization/roleDefinitions'
var role = {
  Owner: '${rdPrefix}/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: '${rdPrefix}/b24988ac-6180-42a0-ab88-20f7382dd24c'
  StorageBlobDataReader: '${rdPrefix}/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
  StorageBlobDataContributor: '${rdPrefix}/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}


param tags object = {
  Owner: 'fasthack'
  Project: 'fasthack'
  Environment: env
  Toolkit: 'bicep'
  Name: prefix
}

var baseName  = '${prefix}${postfix}${env}'
var resourceGroupName = 'P3-${baseName}-RG'
var eventHubNamespacename = '${prefix}ehns${postfix}${env}'
var dataLakeg2SynapseName = '${prefix}adlssyn${postfix}${env}'
var synapseWorkSpaceName = '${prefix}-synapse-${postfix}${env}'
var datalakeName = '${prefix}adl${postfix}${env}'
var keyVaultName = '${prefix}-akv-${postfix}${env}'

//functoion related variables
var appname = '${prefix}-fnapp-${postfix}${env}'
var functionStorageAccountName = '${prefix}stfnapp${postfix}${env}'


var sqladministratorLogin='rootuser'

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourceGroupName
  location: location

  tags: tags
}

// event hub

module ehns './modules/deploy_1_eventhub.bicep' = {
  name: 'eh'
  scope: resourceGroup(rg.name)
  params: {
    eventhubnamespaceName: eventHubNamespacename
    resourceLocation: rg.location
    tags: tags
    skuname:'basic'
    skutier: 'basic'
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
    sparkPoolName: 'strmsparkpool'
    sparkPollNodeSize: 'small'
    sparkPoolMinNodeCount: 3
    sparkPoolMaxNodeCount: 3
  }
}


// data lake

module dl './modules/deploy_3_datalake_account.bicep' = {
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

// functoon deployment

module fnapp './modules/deploy_4_function.bicep' = {
  name: 'fnapp'
  scope: resourceGroup(rg.name)
  params: {
    appName: appname
    location: location
    storageAccountType : 'Standard_LRS'
    appInsightsLocation: location
    functionStorageAccountName: functionStorageAccountName
    runtime: 'python'
    param_EVENT_HUB_CONN_STR_SYNAPSESTREAMING: ehns.outputs.eventHubNamespaceConnectionString
    param_EVENT_HUB_NAME_SYNAPSESTREAMING: ehns.outputs.eventHubName
  }
  dependsOn: [
    ehns    
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
    ehnsconnstring: ehns.outputs.eventHubNamespaceConnectionString
    funtionappKey: fnapp.outputs.defaultfunctionKey
    datalakeName: datalakeName
    
  }
  dependsOn:[
    synapse
    ehns
    fnapp
  ]
}


