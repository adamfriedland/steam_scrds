@description('Globally unique name for the Azure Container Registry.')
param registryName string

@description('Azure region in which to deploy the registry.')
param location string

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  tags: {}
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

output loginServer string = registry.properties.loginServer
