/*region Header
      Module Steps 
      1 - Create Synapse Workspace
      2 - Create your Firewall settings
      3 - Set the minimal TLS version for the SQL Pools 
      4 - Create your Dedicated SQL Pool (Optional)
      5 - Create your Dedicated Apache Spark Pool (Optional)
      6 - Create your Dedicated ADX Kusto Pool (Optional)
      7 - Grant/Set Synapse MSI as SQL Admin
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param synapseWorkspaceName string
param resourceLocation string = resourceGroup().location
param networkIsolationMode string
param tags object

param ctrlDeploySynapseSQLPool bool
param ctrlDeploySynapseSparkPool bool
param ctrlDeploySynapseADXPool bool

@description('Provide the user name for SQL login.')
param sqlAdministratorLogin string

@description('The passwords must meet the following guidelines:<ul><li> The password does not contain the account name of the user.</li><li> The password is at least eight characters long.</li><li> The password contains characters from three of the following four categories:</li><ul><li>Latin uppercase letters (A through Z)</li><li>Latin lowercase letters (a through z)</li><li>Base 10 digits (0 through 9)</li><li>Non-alphanumeric characters such as: exclamation point (!), dollar sign ($), number sign (#), or percent (%).</li></ul></ul> Passwords can be up to 128 characters long. Use passwords that are as long and complex as possible. Visit <a href=https://aka.ms/azuresqlserverpasswordpolicy>aka.ms/azuresqlserverpasswordpolicy</a> for more details.')
@secure()
param sqlAdministratorLoginPassword string

@description('Data Lake Storage account that you will use for Synapse Workspace.')
param defaultDataLakeStorageAccountName string
param defaultDataLakeStorageFileSystemName string
param defaultAdlsGen2AccountResourceId string = ''
param managedResourceGroupName string

//Parameters for the Synapse Firewall
param createManagedPrivateEndpoint bool = false
param startIpaddress string
param endIpAddress string

var defaultDataLakeStorageAccountUrl = 'https://${defaultDataLakeStorageAccountName}.dfs.core.windows.net'

//Paramaters for SQL Pools
param synapseDedicatedSQLPoolName string
param synapseSQLPoolSKU string
param collation string

//Paramaters for Spark Pools
param synapseSparkPoolName string
param synapseSparkPoolNodeSize string
param sparkPoolMinNodeCount int
param sparkPoolMaxNodeCount int

//Paramaters for ADX Kusto Pools
param synapseADXPoolName string
param synapseADXDatabaseName string
param synapseADXPoolEnableAutoScale bool
param synapseADXPoolMinSize int
param synapseADXPoolMaxSize int

//Create Resources----------------------------------------------------------------------------------------------------------------------------

//https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces
//1. Create your Synapse Workspace
resource r_synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseWorkspaceName
  location: resourceLocation
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    azureADOnlyAuthentication: false  
    // connectivityEndpoints: {
    //   web: 'https://web.azuresynapse.net?workspace=%2fsubscriptions%2f${subscription().subscriptionId}2fresourceGroups%2f${resourceGroup().name}%2fproviders%2fMicrosoft.Synapse%2fworkspaces%2f${synapseWorkspaceName}'
    //   dev: 'https://${synapseWorkspaceName}.dev.azuresynapse.net'
    //   sqlOnDemand: '${synapseWorkspaceName}-ondemand.sql.azuresynapse.net'
    //   sql: '${synapseWorkspaceName}.sql.azuresynapse.net'
    // }
    // cspWorkspaceAdminProperties: {
    //   initialWorkspaceAdminObjectId: userObjectId
    // }
    defaultDataLakeStorage: {
      accountUrl: defaultDataLakeStorageAccountUrl
      createManagedPrivateEndpoint: createManagedPrivateEndpoint
      filesystem: defaultDataLakeStorageFileSystemName
      resourceId: defaultAdlsGen2AccountResourceId
    }
    managedResourceGroupName: managedResourceGroupName
    //Setting this to 'default' will ensure that all compute for this workspace is in a virtual network managed on behalf of the user.
    managedVirtualNetwork: 'default'
    managedVirtualNetworkSettings: {
      preventDataExfiltration: false
    }
    //publicNetworkAccess: Post Deployment Script will disable public network access for vNet integrated deployments.
    publicNetworkAccess: 'Enabled'
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
    trustedServiceBypassEnabled: true
    
    //Synapse Git Integration Settings
    //If you want to integrate your GitHub Repo You can go ahead and uncomment these lines below. Just be sure to put in your accountName, DevOps HostName, projectName, and RepoName
    // workspaceRepositoryConfiguration: {
    //   accountName: 'YOURDEVOPSACCOUNTNAME'
    //   collaborationBranch: 'main'
    //   hostName: 'https://dev.azure.com' //https://dev.azure.com/YOURDEVOPSORG/_git/YOURDEVOPSPROJECTNAME
    //   projectName: 'YOURDEVOPSPROJECTNAME'
    //   repositoryName: 'YOURDEVOPSREPONAME'
    //   rootFolder: '/'
    //   tenantId: environment().authentication.tenant
    //   type: 'WorkspaceVSTSConfiguration' //This can either be WorkspaceVSTSConfiguration or WorkspaceGitHubConfiguration
    // }
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/firewallrules
//2. Create your Firewall settings for your Synapse Workspace 
resource r_synapseWorkspaceFirewallAllowAll 'Microsoft.Synapse/workspaces/firewallrules@2021-06-01' = if (networkIsolationMode == 'default') {
  name: 'AllowAllNetworks'
  parent: r_synapseWorkspace 
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

//Allow Azure Services and resources to access this workspace
//Required for Post-Deployment Scripts
resource r_synapseWorkspaceFirewallAllowAzure 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: 'AllowAllWindowsAzureIps' //Please be aware that you have to name it exactly 'AllowAllWindowsAzureIps' or it will error out on you.
  parent: r_synapseWorkspace 
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/firewallrules
resource r_firewall_allowLocalIP 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: 'allowLocalIP'
  parent: r_synapseWorkspace 
  properties: {
    endIpAddress: endIpAddress
    startIpAddress: startIpaddress
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/dedicatedsqlminimaltlssetting
//3. Set the minimal TLS version for the SQL Pools 
resource r_minimumTLS 'Microsoft.Synapse/workspaces/dedicatedSQLminimalTlsSettings@2021-06-01' = {
  name: 'default'
  parent: r_synapseWorkspace
  properties: {
    minimalTlsVersion: '1.2'
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/sqlpools
//4. Create your Dedicated SQL Pool
resource r_sqlPool 'Microsoft.Synapse/workspaces/sqlPools@2021-06-01' = if (ctrlDeploySynapseSQLPool == true) {
  name: synapseDedicatedSQLPoolName
  location: resourceLocation
  parent: r_synapseWorkspace
  sku:{
    name: synapseSQLPoolSKU
  }
  properties:{
    collation: collation
    createMode: 'Default'
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/bigdatapools
//5. Create your Dedicated Apache Spark Pool
resource r_sparkPool 'Microsoft.Synapse/workspaces/bigDataPools@2021-06-01' = if(ctrlDeploySynapseSparkPool == true) {
  name: synapseSparkPoolName
  location: resourceLocation
  parent: r_synapseWorkspace
  properties:{
    autoPause:{
      enabled:true
      delayInMinutes: 15
    }
    autoScale:{
      enabled: true
      minNodeCount: sparkPoolMinNodeCount
      maxNodeCount: sparkPoolMaxNodeCount
    }
    nodeSize: synapseSparkPoolNodeSize
    nodeSizeFamily: 'MemoryOptimized'
    sparkVersion: '3.1'
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/kustopools
//6. Create your Dedicated ADX Kusto Pool
resource r_adxPool 'Microsoft.Synapse/workspaces/kustoPools@2021-06-01-preview' = if (ctrlDeploySynapseADXPool == true) {
  name: synapseADXPoolName
  location: resourceLocation
  parent: r_synapseWorkspace
  properties: {
    enablePurge: false
    enableStreamingIngest: true
    optimizedAutoscale: {
      isEnabled: synapseADXPoolEnableAutoScale
      maximum: synapseADXPoolMaxSize
      minimum: synapseADXPoolMinSize
      version: 1
    } 
    workspaceUID: r_synapseWorkspace.properties.workspaceUID
  }
  sku: {
    capacity: 2
    name: 'Compute optimized'
    size: 'Extra small'
  }
  //Double check this syntax ->https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/kustopools/databases
  resource r_adxDatabase 'databases' = {
    name: synapseADXDatabaseName
    kind: 'ReadWrite'
    location: resourceLocation
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/kustopools/databases?pivots=deployment-language-bicep
// resource symbolicname 'Microsoft.Synapse/workspaces/kustoPools/databases@2021-06-01-preview' = if (ctrlDeploySynapseADXPool == true) {
//   name: synapseADXDatabaseName
//   location: resourceLocation
//   kind: 'ReadWrite'
//   parent: r_adxPool
//   // For remaining properties, see workspaces/kustoPools/databases objects
// }

//https://docs.microsoft.com/en-us/azure/templates/microsoft.synapse/workspaces/managedidentitysqlcontrolsettings
//7. Grant/Set Synapse MSI as SQL Admin
resource r_managedIdentitySqlControlSettings 'Microsoft.Synapse/workspaces/managedIdentitySqlControlSettings@2021-06-01' = {
  name: 'default'
  parent: r_synapseWorkspace
  properties: {
    grantSqlControlToManagedIdentity: {
      desiredState:'Enabled'
    }
  }
}

output synapseManagedIdentityId string = r_synapseWorkspace.identity.principalId
output synapseWorkspaceID string = r_synapseWorkspace.id
output synapseWorkspaceName string = r_synapseWorkspace.name

output synapseSQLDedicatedEndpoint string = r_synapseWorkspace.properties.connectivityEndpoints.sql
output synapseSQLServerlessEndpoint string = r_synapseWorkspace.properties.connectivityEndpoints.sqlOnDemand

output synapseWorkspaceSparkID string = ctrlDeploySynapseSparkPool ? r_sparkPool.id : ''
output synapseWorkspaceSparkName string = ctrlDeploySynapseSparkPool ? r_sparkPool.name : ''

output synapseWorkspaceIdentityPrincipalID string = r_synapseWorkspace.identity.principalId
output synapsePrincipalId string = r_synapseWorkspace.identity.principalId
