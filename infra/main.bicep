// main.bicep: Subscription scope deployment for Cognitive Services and Networking in separate RGs

targetScope = 'resourceGroup'

@description('Primary Azure region (defaults to this resource group location).')
param location string = resourceGroup().location

@allowed([
  'OpenAI'
  'FormRecognizer'
  'SpeechServices'
  'TextTranslation'
  'TextAnalytics'
  'Face'
  'LanguageAuthoring'
  'AIServices'
  'ComputerVision'
  'ContentSafety'
  'HealthInsights'
])
@description('Cognitive Services kind (choose from list)')
param kind string

@allowed(['public','virtualNetwork','privateEndpoint'])
@description('Networking mode (choose from list)')
param networking string

@description('Enable system-assigned managed identity?')
@allowed([true, false])
param enableManagedIdentity bool

var vnetLoc  = toLower(location)

var kindAbbr = kind == 'OpenAI' ? 'oai' :kind == 'FormRecognizer' ? 'fr' :kind == 'SpeechServices' ? 'sp' :kind == 'TextTranslation' ? 'tt' :kind == 'TextAnalytics' ? 'ta' :kind == 'Face' ? 'fc' :kind == 'LanguageAuthoring' ? 'la' :kind == 'AIServices' ? 'ais' :kind == 'ComputerVision' ? 'cv' :kind == 'ContentSafety' ? 'cs' :kind == 'HealthInsights' ? 'hi' : 'cg'

// Names

var case = resourceGroup().name

var vnetName     = 'vnet-${vnetLoc}'
var subnetName   = 'default'
var peName       = 'pe-${kindAbbr}-${case}'
// ensure cognitiveAccountName is within Azure length limits (3-24 chars)
var baseName = toLower('${kindAbbr}-${case}')
var cognitiveAccountName = substring(baseName, 0, min(length(baseName), 24))

var dnsZoneName = kind == 'OpenAI' ? 'privatelink.openai.azure.com' : 'privatelink.cognitiveservices.azure.com'

// ----- Modules -----
module network 'modules/network.bicep' = if (networking == 'virtualNetwork' || networking == 'privateEndpoint') {
  name: 'network'
  params: {
    virtualNetworkName: vnetName
    location: location
    subnetName: subnetName
    addressPrefixes: [ '10.0.0.0/16' ]
    subnetPrefix: '10.0.0.0/24'
  }
}

module cog 'modules/cognitiveAccount.bicep' = {
  name: 'cognitiveAccount'
  params: {
    name: cognitiveAccountName
    location: location
    kind: kind
    enableManagedIdentity: enableManagedIdentity
    networking: networking
    virtualNetworkSubnetIds: (networking == 'virtualNetwork' || networking == 'privateEndpoint') ? [ network.outputs.subnetId ] : []
    customSubDomainName: (networking == 'public' && kind != 'OpenAI') ? '' : cognitiveAccountName
  }
}

module pe 'modules/privateEndpoint.bicep' = if (networking == 'privateEndpoint') {
  name: 'privateEndpoint'
  params: {
    name: peName
    location: location
    targetResourceId: cog.outputs.id
    subnetId: network.outputs.subnetId
    vnetId: network.outputs.vnetId
    vnetName: network.outputs.vnetName
    dnsZoneName: dnsZoneName
  }
}

// ----- Outputs -----
output cognitiveAccountName string = cognitiveAccountName
output vnetName string = vnetName
output peName string = peName
