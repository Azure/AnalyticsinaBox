/*region Header
      Module Steps 
      1 - Deploy VNet
      2 - Deploy Subnets using a loop
      3 - Deploy Default Subnet
      4 - Output back to master module the following params (vNetID, subnetID)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param networkIsolationMode string
param existingVNetResourceGroupName string
param ctrlNewOrExistingVNet string
param vNetName string
param vNetSubnetName string
param vNetIPAddressPrefixes array

var vNetID = ctrlNewOrExistingVNet == 'new' ? r_vNet.id : resourceId(subscription().subscriptionId, existingVNetResourceGroupName, 'Microsoft.Network/virtualNetworks', vNetName)
var subnetID = ctrlNewOrExistingVNet == 'new' ? r_subNet.id : '${vNetID}/subnets/${vNetSubnetName}'

//https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/loops
var subnets = [
  {
    name: 'GatewaySubnet'
    subnetPrefix: '10.17.1.0/29'
  }
  {
    name: 'FESubnet'
    subnetPrefix: '10.17.2.0/24'
  }
  {
    name: 'BESubnet'
    subnetPrefix: '10.17.3.0/24'
  }
  {
    name: 'AISubnet'
    subnetPrefix: '10.17.4.0/24'
  }
  {
    name: 'StorageAccountSubnet'
    subnetPrefix: '10.17.5.0/24'
  }
  {
    name: 'SQLSubnet'
    subnetPrefix: '10.17.6.0/24'
  }
  {
    name: 'SynapseSubnet'
    subnetPrefix: '10.17.7.0/24'
  }
  // {
  //   name: vNetSubnetName
  //   subnetPrefix: '10.17.0.0/24'
  // }
]

//Create Resources----------------------------------------------------------------------------------------------------------------------------
//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks
//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/subnets
//1. vNet created for network protected environments (networkIsolationMode == 'vNet')
resource r_vNet 'Microsoft.Network/virtualNetworks@2020-11-01' = if(networkIsolationMode == 'vNet' && ctrlNewOrExistingVNet == 'new'){
  name: vNetName
  location: resourceLocation
  properties:{
    addressSpace:{
      addressPrefixes: vNetIPAddressPrefixes
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.subnetPrefix
      }
    }]
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/subnets
//2. Create Subnets
resource r_subNet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = if(networkIsolationMode == 'vNet' && ctrlNewOrExistingVNet == 'new') {
  name: vNetSubnetName
  parent: r_vNet
  properties: {
    addressPrefix: '10.17.0.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies:'Enabled'
  }
}

output vNetID string = vNetID
output subnetID string = subnetID
