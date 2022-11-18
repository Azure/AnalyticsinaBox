/*region Header
      SCRIPT STEPS 
      1 - Create the Event Hub Namespace
      2 - Create the Event Hub Shared Access Policies
      3 - Create Network Rules for the Event Hub Namespace
      4 - Create the Event Hubs
      5 - Create the Event Hub's individual SAS Policy
      6 - Create the Consumer Groups for each Event Hub
      7 - Create the Event Hub's Diagnostics and Alert Settings
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param eventhubname string = 'fasthack-eventhub-xx'
param resourceLocation string = resourceGroup().location

//Create Resources----------------------------------------------------------------------------------------------------------------------------

//https://docs.microsoft.com/en-us/azure/templates/microsoft.eventhub/2022-01-01-preview/namespaces
//1. Create the Event Hub Namespace
resource eventhub_namespace 'Microsoft.EventHub/namespaces@2022-01-01-preview' = {
  name: eventhubname
  location: resourceLocation
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 5
  }
  properties: {
    minimumTlsVersion: '1.0'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    zoneRedundant: true
    isAutoInflateEnabled: true
    maximumThroughputUnits: 10
    kafkaEnabled: true
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.eventhub/2022-01-01-preview/namespaces
//2. Create the Event Hub Shared Access Policies
resource RootManageSharedAccessKey 'Microsoft.EventHub/namespaces/AuthorizationRules@2022-01-01-preview' = {
  name: 'RootManageSharedAccessKey'
  parent: eventhub_namespace
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource fasthack_saspolicy 'Microsoft.EventHub/namespaces/AuthorizationRules@2022-01-01-preview' = {
  name: 'fasthack_saspolicy'
  parent: eventhub_namespace
  properties: {
    rights: [
      'Manage'
      'Listen'
      'Send'
    ]
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.eventhub/2022-01-01-preview/namespaces/networkrulesets
//3. Create Network Rules for the Event Hub Namespace
resource eventhub_networkrules 'Microsoft.EventHub/namespaces/networkRuleSets@2022-01-01-preview' = {
  name: 'default'
  parent: eventhub_namespace
  properties: {
    publicNetworkAccess: 'Enabled'
    defaultAction: 'Allow'
    virtualNetworkRules: []
    ipRules: []
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.eventhub/2022-01-01-preview/namespaces/eventhubs
//4. Create the Event Hubs

// param eventhubs array = [
//   'adx-eh'
//   'databricks-eh'
//   'synapse-eh'
//   'entrystream'
//   'exitstream'
// ]

// resource r_eventHubs 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' = [for name in eventhubs:  {
//   name: '${name}'
//   parent: eventhub_namespace
//   properties: {
//     messageRetentionInDays: ('${name}' == 'entrystream' || '${name}' == 'exitstream'  ? 7 : 1)
//     partitionCount: ('${name}' == 'entrystream' || '${name}' == 'exitstream'  ? 4 : 2)
//     status: 'Active'
//   }
// }]

resource adx_eh 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' =  {
  name: 'adx-eh'
  parent: eventhub_namespace
  properties: {
    messageRetentionInDays: 1
    partitionCount: 2
    status: 'Active'
  }
}

resource databricks_eh 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' = {
  name: 'databricks-eh'
  parent: eventhub_namespace
  properties: {
    messageRetentionInDays: 1
    partitionCount: 2
    status: 'Active'
  }
}

resource synapse_eh 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' = {
  name: 'synapse-eh'
  parent: eventhub_namespace
  properties: {
    messageRetentionInDays: 1
    partitionCount: 2
    status: 'Active'
  }
}

resource entrystream_eh 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' = {
  name: 'entrystream'
  parent: eventhub_namespace
  properties: {
    messageRetentionInDays: 7
    partitionCount: 4
    status: 'Active'
  }
}

resource existream_eh 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' = {
  name: 'exitstream'
  parent: eventhub_namespace
  properties: {
    messageRetentionInDays: 7
    partitionCount: 4
    status: 'Active'
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.eventhub/2022-01-01-preview/namespaces/eventhubs/authorizationrules
//5. Create the Event Hub's individual SAS Policy
resource adx_eh_sas 'Microsoft.EventHub/namespaces/eventhubs/authorizationrules@2022-01-01-preview' = {
  name: 'adx_sas'
  parent: adx_eh
  properties: {
    rights: [
      'Manage'
      'Listen'
      'Send'
    ]
  }
}

resource databricks_eh_sas 'Microsoft.EventHub/namespaces/eventhubs/authorizationrules@2022-01-01-preview' = {
  name: 'databricks_sas'
  parent: adx_eh
  properties: {
    rights: [
      'Manage'
      'Listen'
      'Send'
    ]
  }
}


//https://docs.microsoft.com/en-us/azure/templates/microsoft.eventhub/2022-01-01-preview/namespaces/eventhubs/consumergroups
//6. Create the Consumer Groups for each Event Hub

param consumergroups array = [
  '$Default'
  'adx-cg'
  'databricks-cg'
  'dotnet-cg'
  'iotexplorer-cg'
  'logicapp-cg'
  'servicebusexplorer-cg'
  'streaminganalytics-cg'
  'synapse-cg'
  'vscode-cg'
]

//ADX EH CGs
resource adx_eh_Default_cg 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2022-01-01-preview' = [for name in consumergroups: {
  name: '${name}'
  parent: adx_eh
  properties: {
  }
}]

//Databricks EH CGs
resource databricks_eh_Default_cg 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2022-01-01-preview' = [for name in consumergroups: {
  name: '${name}'
  parent: databricks_eh
  properties: {
  }
}]

//Synapse EH CGs
resource synapse_eh_Default_cg 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2022-01-01-preview' = [for name in consumergroups: {
  name: '${name}'
  parent: synapse_eh
  properties: {
  }
}]

//Entry Stream EH CGs
resource entrystream_eh_Default_cg 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2022-01-01-preview' = [for name in consumergroups: {
  name: '${name}'
  parent: entrystream_eh
  properties: {
  }
}]

//Exit Stream EH CGs
resource exitstream_eh_Default_cg 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2022-01-01-preview' = [for name in consumergroups: {
  name: '${name}'
  parent: existream_eh
  properties: {
  }
}]


//PLACE HOLDER FOR CREATING THE DIAGNOSTICS AND ALERTS FOR EVENT HUBS
//7. Create the Event Hub's Diagnostics and Alert Settings
