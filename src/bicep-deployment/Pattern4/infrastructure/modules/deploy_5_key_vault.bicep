param name string
param location string
param tags object
param objectID string
param synapseManageIdentity string
param administratorLogin string
@secure()
param administratorLoginPassword string
param sqlservername string
param sqlserverDBName string
param sqlconnectionstring string

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
        objectId: objectID
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
    name: 'sampledb'
    properties: {
      value: sqlserverDBName
    }
  }
  resource secret4 'secrets' = {
    name: 'sqlconn-sampledb'
    properties: {
      value: sqlconnectionstring
    }
  }
  tags: tags
}

output kvOut string = kv.id
