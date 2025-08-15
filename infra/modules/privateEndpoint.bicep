// modules/privateEndpoint.bicep (rg scope)

targetScope = 'resourceGroup'

param name string
param location string
param targetResourceId string
param subnetId string
param vnetId string
param vnetName string
param dnsZoneName string

resource dnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: dnsZoneName
  location: 'global'
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${vnetName}-link'
  parent: dnsZone
  location: 'global' // explicit location required for this definition
  properties: {
    virtualNetwork: { id: vnetId }
    registrationEnabled: false
  }
}

resource pe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: name
  location: location
  properties: {
    subnet: { id: subnetId }
    privateLinkServiceConnections: [ {
      name: '${name}-conn'
      properties: { privateLinkServiceId: targetResourceId, groupIds: [ 'account' ] }
    } ]
  }
}

resource zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: 'default'
  parent: pe
  location: location // ensure location is present for this nested resource
  properties: { privateDnsZoneConfigs: [ { name: 'config', properties: { privateDnsZoneId: dnsZone.id } } ] }
}
