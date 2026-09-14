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

@description('Object ID of the principal (service principal/managed identity) that should be granted AcrPush access to build and push images.')
param acrPushPrincipalId string

param tags object = {}

var acrPushRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')

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

resource acrPushRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(acrPushPrincipalId)) {
  name: guid(registry.id, acrPushPrincipalId, acrPushRoleDefinitionId)
  scope: registry
  properties: {
    roleDefinitionId: acrPushRoleDefinitionId
    principalId: acrPushPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output loginServer string = registry.properties.loginServer
