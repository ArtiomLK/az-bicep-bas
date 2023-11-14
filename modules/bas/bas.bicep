param location string = resourceGroup().location
param tags object

param bas_n string
param vnet_id string
param snet_bas_id string
param pip_id string
@allowed([
  'Developer'
  'Basic'
  'Standard'
])
param bas_sku string
param bas_enableTunneling bool
param bas_enableIpConnect bool
param bas_enableShareableLink bool
param enableKerberos bool

var bas_properties = bas_sku == 'Developer' ? {
  virtualNetwork: {
    id: vnet_id
  }
} : {
  ipConfigurations: [
    {
      name: 'IpConf'
      properties: {
        subnet: {
          id: snet_bas_id
        }
        publicIPAddress: {
          id: pip_id
        }
      }
    }
  ]
  enableTunneling: bas_enableTunneling
  enableIpConnect: bas_enableIpConnect
  enableShareableLink: bas_enableShareableLink
  enableKerberos: enableKerberos
  disableCopyPaste: false
}

resource bastionHost 'Microsoft.Network/bastionHosts@2023-04-01' = {
  name: bas_n
  location: location
  properties: bas_properties
  sku: {
    name: bas_sku
  }
  tags: tags
}
