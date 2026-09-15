@description('Azure region for deployment.')
param location string

@description('Name of the container group.')
param containerName string

@description('Container registry login server used when imageType is Private.')
param imageRegistryLoginServer string

@description('Name of the existing user-assigned identity used to pull the image.')
param managedIdentityName string

@description('Port mappings for the container group.')
param ports array = [
  {
    port: 27015
    protocol: 'UDP'
  }
]

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

var registryCredentials = [
  {
    server: imageRegistryLoginServer
    identity: managedIdentity.id
  }
]

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2022-10-01-preview' = {
  name: containerName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  zones: []
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          image: '${imageRegistryLoginServer}/steam-scrds:latest'
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
          ports: ports
        }
      }
    ]
    restartPolicy: 'Never'
    osType: 'Linux'
    sku: 'Standard'
    imageRegistryCredentials: registryCredentials
    ipAddress: {
      type: 'Public'
      ports: ports
    }
  }
}
