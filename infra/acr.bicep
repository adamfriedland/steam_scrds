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

@description('Object ID of the principal managed identity that should be granted to access to build and push images.')
param managedIdentityPrincipalId string

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

var containerWriterRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a1e307c-b015-4ebd-883e-5b7698a07328')

resource acrPushRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(registry.id, managedIdentityPrincipalId, containerWriterRoleDefinitionId)
  scope: registry
  properties: {
    roleDefinitionId: containerWriterRoleDefinitionId
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output loginServer string = registry.properties.loginServer
