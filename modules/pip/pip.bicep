
param location string = resourceGroup().location
param tags object

param pip_n string

resource bastionPublicIpAddress 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: pip_n
  tags: tags
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

output id string = bastionPublicIpAddress.id
