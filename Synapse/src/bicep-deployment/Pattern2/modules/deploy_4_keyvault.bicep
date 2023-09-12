/*region Header
      Module Steps 
      1 - Create User-Assignment Managed Identity used to execute deployment scripts
      2 - Create Key Vault
      3 - Create Necessary Secrets
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param keyVaultName string
param deploymentScriptUAMIName string
param spObjectId string

@secure()
param storageAccountKey string 
param storageAccountCnx string

param administratorLogin string
@secure()
param administratorLoginPassword string
param sqlServerName string
param sqlServerDBName string
param sqlCnxString string

//var vaultUri = toLower('https://${keyVaultName}.vault.azure.net/')

//Create Resources----------------------------------------------------------------------------------------------------------------------------

//https://docs.microsoft.com/en-us/azure/templates/microsoft.managedidentity/userassignedidentities
//1. User-Assignment Managed Identity used to execute deployment scripts
resource r_deploymentScriptUAMI 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: deploymentScriptUAMIName
  location: resourceLocation
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults
//2. Create Key Vault
resource r_keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = { 
  name: keyVaultName
  location: resourceLocation
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    networkAcls: { //Rules governing the accessibility of the key vault from specific network locations.
      //defaultAction: (networkIsolationMode == 'vNet')? 'Deny' : 'Allow'
      //bypass:'AzureServices'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: r_deploymentScriptUAMI.properties.principalId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: spObjectId //This is your Service Principal Object ID so you can give the SP access to the Key Vault Secrets
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
        }
      }
    ]
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableRbacAuthorization: false
    provisioningState: 'Succeeded'
    publicNetworkAccess: 'Enabled'
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets
//3. Create Necessary Secrets
resource vault_secret_ADLS_AccountKey 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: 'ADLS--AccountKey'
  parent: r_keyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: storageAccountKey
  }
}

resource vault_secret_ADLS_Cnx 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: 'ADLS--Cnx'
  parent: r_keyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: storageAccountCnx
  }
}

resource vault_secret_ServicePrincipalSecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: 'ServicePrincipalSecret'
  parent: r_keyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: 'ServicePrincipalSecret'
  }
}

resource vault_secret__TenantId 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: 'TenantId'
  parent: r_keyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: subscription().tenantId
  }
}

resource vault_secret__ConnectionStrings_CnxDB 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: 'ConnectionStrings--CnxDB'
  parent: r_keyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: sqlCnxString
  }
}

resource vault_secret__ConnectionStrings_CnxDB_Admin 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: 'ConnectionStrings--CnxDB--Admin'
  parent: r_keyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: administratorLogin
  }
}

resource vault_secret__ConnectionStrings_CnxDB_Password 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: 'ConnectionStrings--CnxDB--Password'
  parent: r_keyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: administratorLoginPassword
  }
}

resource vault_secret__Svr 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: 'AzureSQL-Server'
  parent: r_keyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: sqlServerName
  }
}

resource vault_secret__SQLDB 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: 'AzureSQL-DB'
  parent: r_keyVault
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'string'
    value: sqlServerDBName
  }
}


 output keyVaultID string = r_keyVault.id
 output keyVaultName string = r_keyVault.name
 output deploymentScriptUAMIName string = r_deploymentScriptUAMI.name
 output deploymentScriptUAMIResourceId string = r_deploymentScriptUAMI.id
 output deploymentScriptUAMIPrincipalId string = r_deploymentScriptUAMI.properties.principalId

