param name string
param location string
param tags object
param roleAssignmentPrincipalID string
param roleDefinitionId string
param roleAssignmnetPrincipalType string

// Storage Account
resource stoacct 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    supportsHttpsTrafficOnly: true
  }

  tags: tags
}

output stoacctOut string = stoacct.id

// giving storage blob data contributor access to  synapse manage identity.
resource role1 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name:  guid('ra01${name}')
  scope: stoacct
  properties:{
    principalId: roleAssignmentPrincipalID
    principalType: roleAssignmnetPrincipalType
    roleDefinitionId:  roleDefinitionId
  }
}


// enabling the blob service
resource blob 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name:  '${stoacct.name}/default'
}

// creating the raw container
resource raw_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${stoacct.name}/default/staging'
  properties: {
    publicAccess: 'None'
  }
  dependsOn:[
    blob
  ]
} 
