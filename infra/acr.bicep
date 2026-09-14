@description('Globally unique name for the Azure Container Registry.')
param registryName string

@description('Azure region in which to deploy the registry.')
param location string

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param registrySku string = 'Basic'

@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@allowed([
  'Enabled'
  'Disabled'
])
param zoneRedundancy string = 'Disabled'

param dataEndpointEnabled bool = false

param tags object = {}

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  tags: tags
  sku: {
    name: registrySku
  }
  properties: {
    dataEndpointEnabled: dataEndpointEnabled
    publicNetworkAccess: publicNetworkAccess
    zoneRedundancy: zoneRedundancy
  }
}

output loginServer string = registry.properties.loginServer
