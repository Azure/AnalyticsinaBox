param name string
param location string
param tags object
param roleAssignmentPrincipalID string
param roleDefinitionId string
param roleAssignmnetPrincipalType string

// Storage Account
resource datalake 'Microsoft.Storage/storageAccounts@2019-04-01' = {
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
    isHnsEnabled: true
  }

  tags: tags
}

output sdatalakeOut string = datalake.id


// giving storage blob data contributor synapse manage identity.
resource role1 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name:  guid('ra01${name}')
  scope: datalake
  properties:{
    principalId: roleAssignmentPrincipalID
    principalType: roleAssignmnetPrincipalType
    roleDefinitionId:  roleDefinitionId
  }
}


// enabling the blob service
resource blob 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name:  '${datalake.name}/default'
}

// creating the raw container
resource raw_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${datalake.name}/default/raw'
  properties: {
    publicAccess: 'None'
  }
  dependsOn:[
    blob
  ]
} 

// creating the curated container
resource curated_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${datalake.name}/default/curated'
  properties: {
    publicAccess: 'None'
  }
  dependsOn:[
    blob
  ]
} 

