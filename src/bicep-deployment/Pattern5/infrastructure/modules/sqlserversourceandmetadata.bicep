param serverName string
param location string
param tags object
param administratorLogin string
@secure()
param administratorLoginPassword string
param databaseNameWWI string
param databaseNameMetadata string
param objectID string
param userPrincipalSQLAdmin string



resource sqlserver 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: serverName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      login: userPrincipalSQLAdmin
      sid: objectID
      azureADOnlyAuthentication: false
    }
  }
  resource firewall 'firewallRules' = {
    name: 'allowAll'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
    }
  }
}


resource sqlserverdatabaseWWI 'Microsoft.Sql/servers/databases@2021-11-01'= {
  name: databaseNameWWI
  location: location
  tags: tags
  sku: {
    name: 'GP_S_Gen5_4'
    tier: 'GeneralPurpose'
    }
  parent: sqlserver
  properties: {
    autoPauseDelay: 60
    minCapacity: json('0.5')
    //sampleName: 'WideWorldImportersStd'
    }
}
 
resource sqlserverdatabaseMetadata 'Microsoft.Sql/servers/databases@2021-11-01-preview' = {
  name: databaseNameMetadata
  location: location
  tags: tags
  sku: {
    name: 'GP_S_Gen5_1'
    tier: 'GeneralPurpose'
  }
  parent: sqlserver
  properties: {
    autoPauseDelay: 60
    minCapacity: json('0.5')
    }
}

output sqlservername string = sqlserver.properties.fullyQualifiedDomainName
output sqlserverDBNameWWI  string =sqlserverdatabaseWWI.name
output sqlserverDBNameMetadata string = sqlserverdatabaseMetadata.name

output sqlserverFQDN string = sqlserver.properties.fullyQualifiedDomainName
