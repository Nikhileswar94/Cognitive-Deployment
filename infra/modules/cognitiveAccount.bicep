// modules/cognitiveAccount.bicep (rg scope)

targetScope = 'resourceGroup'

param name string
param location string = resourceGroup().location
param kind string
param enableManagedIdentity bool = true
param networking string
param virtualNetworkSubnetIds array = []
param skuName string = 'S0' 
// new optional param to accept a custom subdomain (empty means omit)
param customSubDomainName string = ''

var vnetRules = [for s in virtualNetworkSubnetIds: {
  id: s
  ignoreMissingVnetServiceEndpoint: true
}]

// build properties object and only include customSubDomainName when provided
var baseProperties = {
  publicNetworkAccess: networking == 'privateEndpoint' ? 'Disabled' : 'Enabled'
  networkAcls: networking == 'virtualNetwork' ? {
    defaultAction: 'Deny'
    virtualNetworkRules: vnetRules
    ipRules: []
  } : null
}

var accountProperties = union(baseProperties, customSubDomainName == '' ? {} : { customSubDomainName: customSubDomainName })

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  kind: kind
  sku: { name: skuName }
  identity: enableManagedIdentity ? { type: 'SystemAssigned' } : null
  properties: accountProperties
}

output id string = account.id
