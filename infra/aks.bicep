@description('Azure region for deployment.')
param location string

@description('Name of the AKS cluster.')
param clusterName string = 'hl2dm-aks'

@description('DNS prefix used by the AKS API server.')
param dnsPrefix string = clusterName

@description('Resource ID of the user-assigned identity used by the AKS kubelet to pull from ACR.')
param managedIdentityResourceId string

@description('AKS node VM size.')
param vmSize string = 'Standard_B2as_v2'

@description('Number of Linux worker nodes.')
@minValue(1)
param nodeCount int = 1

resource aks 'Microsoft.ContainerService/managedClusters@2026-05-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'system'
        count: nodeCount
        vmSize: vmSize
        osType: 'Linux'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
      }
    ]
    identityProfile: {
      kubeletidentity: {
        resourceId: managedIdentityResourceId
      }
    }
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      outboundType: 'loadBalancer'
    }
  }
}

output clusterName string = aks.name
