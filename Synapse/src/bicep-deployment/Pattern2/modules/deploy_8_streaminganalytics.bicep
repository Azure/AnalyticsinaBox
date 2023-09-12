/*region Header
      Module Steps 
      1 - Create Streaming Analytics Job
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param streamAnalyticsJobName string = 'fasthack-asa-xx'
param streamAnalyticsJobSku string
param resourceLocation string = resourceGroup().location

@allowed([
  'eventhub'
  'iothub'
])
param ctrlStreamIngestionService string = 'eventhub'

//Create Resources----------------------------------------------------------------------------------------------------------------------------
//https://docs.microsoft.com/en-us/azure/templates/microsoft.streamanalytics/streamingjobs
//1. Create Streaming Analytics Job
resource r_streamAnalyticsJob 'Microsoft.StreamAnalytics/streamingjobs@2020-03-01' = {
  name: streamAnalyticsJobName
  location: resourceLocation
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    sku:{
      name:streamAnalyticsJobSku
    }
    jobType:'Cloud'
  }
}

//Assign Event Hubs Data Owner role to Azure Stream Analytics in the EventHubs namespace as per https://docs.microsoft.com/en-us/azure/stream-analytics/event-hubs-managed-identity#grant-the-stream-analytics-job-permissionsto-access-the-event-hub
// resource r_azureStreamAnalyticsEventHubsDataReceiverRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (ctrlStreamIngestionService == 'eventhub') {
//   name: guid(eventHubNamespaceName, streamAnalyticsJobName, 'Event Hubs Data Receiver')
//   scope:r_eventHubNamespace
//   properties:{
//     roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureEventHubsDataOwnerRABCRoleID)
//     principalId: ctrlStreamIngestionService == 'eventhub' ? r_streamAnalyticsJob.identity.principalId : ''
//     principalType:'ServicePrincipal'
//   }
// }

//Assign IoT Hub Data Reader role to Azure Stream Analytics in the IoTHub as per https://docs.microsoft.com/en-us/azure/iot-hub/iot-hub-dev-guide-azure-ad-rbac#manage-access-to-iot-hub-by-using-azure-rbac-role-assignment
// resource r_azureIoTHubDataReceiverRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (ctrlStreamIngestionService == 'iothub') {
//   name: guid(iotHubName, streamAnalyticsJobName, 'IoT Hub Data Receiver')
//   scope:r_iotHub
//   properties:{
//     roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureIoTHubDataReaderRBACRoleID)
//     principalId: (ctrlStreamIngestionService == 'iothub') ? r_streamAnalyticsJob.identity.principalId : ''
//     principalType:'ServicePrincipal'
//   }
// }

output streamAnalyticsIdentityPrincipalID string = r_streamAnalyticsJob.identity.principalId
output streamAnalyticsJobID string = r_streamAnalyticsJob.id
output streamAnalyticsJobName string = r_streamAnalyticsJob.name
// output iotHubName string = (ctrlStreamIngestionService == 'iothub') ? r_iotHub.name : ''
// output iotHubID string = (ctrlStreamIngestionService == 'iothub') ? r_iotHub.id : ''
// output iotHubPrincipalID string = (ctrlStreamIngestionService == 'iothub') ? r_iotHub.identity.principalId : ''
// output eventHubNamespaceName string = (ctrlStreamIngestionService == 'eventhub') ? r_eventHubNamespace.name : ''
// output eventHubNamespaceID string = (ctrlStreamIngestionService == 'eventhub') ? r_eventHubNamespace.id : ''
