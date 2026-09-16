using './hl2dm-vm.bicep'

param location = 'southafricanorth'
param vmName = 'hl2dm'
param adminUsername = ''
param adminSshPublicKey = ''
param sshSourceAddressPrefix = '0.0.0.0/32'
