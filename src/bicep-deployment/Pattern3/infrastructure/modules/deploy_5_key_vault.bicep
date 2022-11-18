param name string
param location string
param tags object
param objectID string
param synapseManageIdentity string
@secure()
param ehnsconnstring string
param funtionappKey string
param datalakeName string


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
    name: 'eh-conn-str'
    properties: {
      value: ehnsconnstring
    }
  }
  resource secret1 'secrets' = {
    name: 'funtionappKey'
    properties: {
      value: funtionappKey
    }
  }
  resource secret_datalake 'secrets' = {
    name: 'datalakeName'
    properties: {
      value: datalakeName
    }
  }
  tags: tags
}

output kvOut string = kv.id
