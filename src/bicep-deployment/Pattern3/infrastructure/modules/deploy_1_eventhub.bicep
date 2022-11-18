/*region Header
      SCRIPT STEPS 
      1 - Create the Event Hub Namespace
      2 - Create the Event Hub Shared Access Policies
      3 - Create Network Rules for the Event Hub Namespace
      4 - Create the Event Hubs
      4.a create the event hub shared access policy
      5 - Create the Event Hub's individual SAS Policy
      6 - Create the Consumer Groups for each Event Hub
      7 - Create the Event Hub's Diagnostics and Alert Settings
      8 - Send the Output back to the main.bicep
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param eventhubnamespaceName string
param resourceLocation string
param tags object
param skuname string
param skutier string
//Create Resources----------------------------------------------------------------------------------------------------------------------------

//https://docs.microsoft.com/en-us/azure/templates/microsoft.eventhub/2022-01-01-preview/namespaces
//1. Create the Event Hub Namespace
resource eventhub_namespace 'Microsoft.EventHub/namespaces@2022-01-01-preview' = {
  name: eventhubnamespaceName
  location: resourceLocation
  tags: tags
  sku: {
    name: skuname
    tier: skutier
    capacity: 1
  }
  properties: {
    minimumTlsVersion: '1.0'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    zoneRedundant: true
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
    kafkaEnabled: false
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.eventhub/2022-01-01-preview/namespaces
//2. Create the Event Hub Shared Access Policies
// resource ManageAccessPolicynamespace 'Microsoft.EventHub/namespaces/AuthorizationRules@2022-01-01-preview' = {
//   name: 'ManageAccessPolicynamespace'
//   parent: eventhub_namespace
//   properties: {
//     rights: [      
//       'Manage','Listen','Send'   
//     ]
//   }
// }




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

resource synapse_eh 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' =  {
  name: 'synapse-streaming-eh'
  parent: eventhub_namespace
  properties: {
    messageRetentionInDays: 1
    partitionCount: 2
    status: 'Active'
  }
}

// 4.a create the event hub shared access policy

resource synapse_eh_access_policy 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2022-01-01-preview' = {
  name: 'synapse_eh_access_policy'
  parent: synapse_eh
  properties: {
    rights: [
      'Manage','Listen','Send'
    ]
  }
}


//https://docs.microsoft.com/en-us/azure/templates/microsoft.eventhub/2022-01-01-preview/namespaces/eventhubs/consumergroups
//6. Create the Consumer Groups for each Event Hub

param consumergroups array = [
  '$Default'
]

//ADX EH CGs
resource synapse_streaming_eh_cg 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2022-01-01-preview' = [for name in consumergroups:  if(skutier != 'basic') {
  name: '${name}'
  parent: synapse_eh
  properties: {
  }
}]


//PLACE HOLDER FOR CREATING THE DIAGNOSTICS AND ALERTS FOR EVENT HUBS
//7. Create the Event Hub's Diagnostics and Alert Settings

//8. Output


// Determine our connection string

var eventHubNamespaceConnectionString = listKeys(synapse_eh_access_policy.id, synapse_eh_access_policy.apiVersion).primaryConnectionString

// Output our variables

output eventHubNamespaceConnectionString string = eventHubNamespaceConnectionString
output eventHubNameSpaceName string = eventhub_namespace.name
output eventHubName string = synapse_eh.name

