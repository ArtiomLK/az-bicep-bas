param location string = resourceGroup().location
param tags object

param bas_n string
param snet_bas_id string
param pip_id string
@allowed([
  'Standard'
  'Basic'
])
param bas_sku string
param bas_enableTunneling bool
param bas_enableIpConnect bool
param bas_enableShareableLink bool
param enableKerberos bool


resource bastionHost 'Microsoft.Network/bastionHosts@2022-11-01' = {
  name: bas_n
  location: location
  properties: {
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
  sku: {
    name: bas_sku
  }
  tags: tags
}
