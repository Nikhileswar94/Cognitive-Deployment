// modules/network.bicep (rg scope)

targetScope = 'resourceGroup'

param virtualNetworkName string
param location string
param addressPrefixes array
param subnetName string
param subnetPrefix string

resource VNet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: { addressPrefixes: addressPrefixes }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01'= {
  name: subnetName
  parent: VNet
  properties: {
    addressPrefix: subnetPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    serviceEndpoints: [ { service: 'Microsoft.CognitiveServices' } ]
  }
}

var vnetId = VNet.id
var computedSubnetId = subnet.id

output vnetId string = vnetId
output subnetId string = computedSubnetId
output vnetName string = virtualNetworkName
