// linked services - this is not supported as of 2/22/23 in Synapse
param sqlserverFQDN string
param sqlserverDBMetadata string
param workspaceName string
//param workspaceId string

var sqlConnStringMetadata = 'Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=${sqlserverFQDN};Initial Catalog=${sqlserverDBMetadata}'

resource workspaceName_SynapseMetadataOrchestration 'Microsoft.Synapse/workspaces/linkedServices@2019-06-01-preview' = {
  name: '${workspaceName}/SynapseMetadataOrchestration'
  properties: {
    /* parameters: {
      fqdn: {
        type: 'string'
        defaultValue: sqlserverFQDN
      }
      dbname: {
        type: 'string'
        defaultValue: sqlserverDBMetadata
      }
    }*/
    type: 'AzureSqlDatabase'
    typeProperties: {
      connectionString: sqlConnStringMetadata
    }
    connectVia: {
      referenceName: 'AutoResolveIntegrationRuntime'
      type: 'IntegrationRuntimeReference'
    }
  }
  /* dependsOn: [
  '${workspaceId}/integrationRuntimes/AutoResolveIntegrationRuntime'
  ] */
}


