@description('Azure region for deployment.')
param location string

@description('Name of the virtual machine and related network resources.')
param vmName string = 'hl2dm'

@description('Linux administrator username.')
param adminUsername string

@description('SSH public key for the Linux administrator.')
param adminSshPublicKey string

@description('CIDR range allowed to connect to SSH.')
param sshSourceAddressPrefix string

@description('VM size. Must be an x64 SKU since the HL2DM dedicated server binaries are x86_64-only.')
param vmSize string = 'Standard_B2as_v2'

var vnetName = '${vmName}-vnet'
var subnetName = 'default'
var publicIpName = '${vmName}-pip'
var nsgName = '${vmName}-nsg'
var nicName = '${vmName}-nic'
var cloudInitData = replace(loadTextContent('hl2dm-cloud-init.yaml'), '__ADMIN_USERNAME__', adminUsername)

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: sshSourceAddressPrefix
          destinationPortRange: '22'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'allow-game'
        properties: {
          priority: 110
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Udp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '27015'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'allow-rcon'
        properties: {
          priority: 111
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '27015'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'allow-steam-query'
        properties: {
          priority: 120
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Udp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '27005'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'allow-steam-networking'
        properties: {
          priority: 130
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Udp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '27020'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: location
  dependsOn: [
    vnet
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 30
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      customData: base64(cloudInitData)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminSshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

output publicIpAddress string = publicIp.properties.ipAddress
output sshCommand string = 'ssh ${adminUsername}@${publicIp.properties.ipAddress}'
