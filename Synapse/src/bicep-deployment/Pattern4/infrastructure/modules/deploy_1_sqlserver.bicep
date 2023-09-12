param name string
param location string
param tags object
param administratorLogin string
@secure()
param administratorLoginPassword string
param databaseName string



resource sqlserver 'Microsoft.Sql/servers@2021-11-01-preview' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
  resource firewall 'firewallRules' = {
    name: 'allowAll'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
    }
  }
}


resource sqlserverdatabase 'Microsoft.Sql/servers/databases@2021-11-01-preview' = {
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: 'GP_S_Gen5_1'
    tier: 'GeneralPurpose'
  }
  parent: sqlserver
  properties: {
    autoPauseDelay: 60
    sampleName: 'AdventureWorksLT'
    minCapacity: json('0.5')
    }
}


output sqlservername string = sqlserver.properties.fullyQualifiedDomainName
output sqlserverDBName  string =sqlserverdatabase.name


