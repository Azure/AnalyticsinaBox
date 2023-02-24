param name string
param location string
param tags object
param objectIDUser string
param objectIDDevOps string
param synapseManageIdentity string
param administratorLogin string
@secure()
param administratorLoginPassword string
param sqlservername string
param sqlserverDBNameWWI string
param sqlconnectionstringWWI string
param sqlserverDBNameMetadata string
param sqlconnectionstringMetadata string
// param sqlconnectionstringMetadataAAD string can't do AAD connection
// param sqlconnectionstringWWIAAD string

// Key Vault
resource kv 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: name
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: [
      {
        objectId: objectIDUser
        permissions: {          
          secrets: [
            'all'
          ]          
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: objectIDDevOps
        permissions: {          
          secrets: [
            'all'
          ]          
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: synapseManageIdentity
        permissions: {          
          secrets: [
            'get'
            'list'
          ]          
        }
        tenantId: subscription().tenantId
      }
    ]
    
  }
  resource secret 'secrets' = {
    name: 'sql-secret'
    properties: {
      value: administratorLoginPassword
    }
  }
  resource secret1 'secrets' = {
    name: 'sql-user'
    properties: {
      value: administratorLogin
    }
  }
  resource secret2 'secrets' = {
    name: 'sql-svr'
    properties: {
      value: sqlservername
    }
  }
  resource secret3 'secrets' = {
    name: 'wwidb'
    properties: {
      value: sqlserverDBNameWWI
    }
  }
  resource secret4 'secrets' = {
    name: 'sqlconn-wwidb'
    properties: {
      value: sqlconnectionstringWWI
    }
  }
  resource secret5 'secrets' = {
    name: 'metadatadb'
    properties: {
      value: sqlserverDBNameMetadata
    }
  }
  resource secret6 'secrets' = {
    name: 'sqlconn-metadatadb'
    properties: {
      value: sqlconnectionstringMetadata
    }
  }
 /* resource secret7 'secrets' = {
    name: 'aadconn-metadatadb'
    properties: {
      value: sqlconnectionstringMetadataAAD
    }
  }
  resource secret8 'secrets' = {
    name: 'aadconn-wwidb'
    properties: {
      value: sqlconnectionstringWWIAAD
    }
  } */
  tags: tags
}

output kvOut string = kv.id
