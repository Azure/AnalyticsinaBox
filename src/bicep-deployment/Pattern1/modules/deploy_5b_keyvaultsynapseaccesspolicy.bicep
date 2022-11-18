/*region Header
      Module Steps 
      1 - Get existing Key Vault
      2 - Create Access Policy for Synapse Service Principal
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------

param keyVaultName string
param synapseManagedIdentityId string

//Create Resources----------------------------------------------------------------------------------------------------------------------------
resource r_keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

resource r_SynapsePurviewAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  name: 'add'
  parent: r_keyVault
  properties:{
    accessPolicies: [
      //Access Policy to allow Synapse to Get and List Secrets
      //https://docs.microsoft.com/en-us/azure/data-factory/how-to-use-azure-key-vault-secrets-pipeline-activities
      {
        objectId: synapseManagedIdentityId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}
