@description('Azure region for deployment.')
param location string

@description('Name of the container group.')
param containerName string

@description('Container registry login server used when imageType is Private.')
param imageRegistryLoginServer string

@description('Container registry username used when imageType is Private.')
param imageUsername string

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
    username: imageUsername
    password: ''
  }
]

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2022-10-01-preview' = {
  name: containerName
  location: location
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
