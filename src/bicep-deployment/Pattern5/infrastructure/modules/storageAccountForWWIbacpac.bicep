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

// giving storage blob data contributor access to  synapse devops service principal.
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
  name: '${stoacct.name}/default/wwidacpac'
  properties: {
    publicAccess: 'None'
  }
  dependsOn:[
    blob
  ]
} 

// create storage account for bacpac -- too big so will hae to load in YAML
/* resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deployscript-upload-blob-${utcValue}'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: stoacct.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: stoacct.listKeys().keys[0].value
      }
      {
        name: 'CONTENT'
        value: loadFileAsBase64('../data/WWIStd.bacpac')
     
    ]
  }
} }*/
