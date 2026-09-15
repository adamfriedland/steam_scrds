@description('Azure region for deployment.')
param location string

@description('Name of the container group.')
param containerName string

@description('Container registry login server used when imageType is Private.')
param imageRegistryLoginServer string

@description('Resource ID of the existing user-assigned identity used to pull the image.')
param managedIdentityResourceId string

@description('Port mappings for the container group.')
param ports array = [
  {
    port: 27015
    protocol: 'UDP'
  }
]

var registryCredentials = [
  {
    server: imageRegistryLoginServer
    identity: managedIdentityResourceId
  }
]

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2022-10-01-preview' = {
  name: containerName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityResourceId}': {}
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
