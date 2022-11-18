/*region Header
      Module Steps 
      1 - Create Azure SQL Server
      2 - Update Azure SQL Server Firewall Settings
      3 - Create Azure SQL DB
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param sqlservername string
param tags object

param administratorLogin string
@secure()
param administratorLoginPassword string
param databaseName string

//Create Resources----------------------------------------------------------------------------------------------------------------------------

//https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers?pivots=deployment-language-bicep
//1. Create Azure SQL Server
resource r_sqlserver 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: sqlservername
  location: resourceLocation
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers/firewallrules
//2. Update Azure SQL Server Firewall
resource r_sqlfirewallrule 'Microsoft.Sql/servers/firewallRules@2022-02-01-preview' = {
  name: 'allowAll'
  parent: r_sqlserver
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers/databases
//3. Create Azure SQL DB
resource r_sqlserverdatabase 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  name: databaseName
  location: resourceLocation
  parent: r_sqlserver
  tags: tags
  sku: {
    name: 'GP_S_Gen5_1'
    tier: 'GeneralPurpose'
  }
  properties: {
    autoPauseDelay: 60
    sampleName: 'AdventureWorksLT'
    minCapacity: json('0.5')
  }
}

output sqlServerNameDomainName string = r_sqlserver.properties.fullyQualifiedDomainName
output sqlServerName string = r_sqlserver.name
output sqlserverDBName  string = r_sqlserverdatabase.name
