// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
param tags object = {}
@description('environment name. dev, qa, uat, stg, prod, etc.')
param env string
param location string = resourceGroup().location
// ------------------------------------------------------------------------------------------------
// Bastion parameters
// ------------------------------------------------------------------------------------------------
@description('Bastion vnet name. vnet-hub-extension-bas-dev-eastus')
param bas_n string = 'bas-${location}-${env}'
param bas_enableTunneling bool = true
param bas_enableIpConnect bool = true
param bas_enableShareableLink bool = true
param bas_enableKerberos bool = false
@allowed([
  'Standard'
  'Basic'
])
param bas_sku string = 'Standard'
param vnet_bas_n string = 'vnet-hub-extension-bas-${location}-${env}'
param vnet_bas_addr string
param bas_nsg_n string = 'nsg-bas-${location}-${env}'
param bas_pip_n string = 'pip-bas-${location}-${env}'

// ------------------------------------------------------------------------------------------------
// Bastion - Deploy Azure Bastion
// ------------------------------------------------------------------------------------------------
module nsgBastion 'components/nsg/nsgBas.bicep' = {
  name: bas_nsg_n
  params: {
    nsgName: bas_nsg_n
    location: location
    tags:tags
  }
}

resource vnetBastion 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: vnet_bas_n
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_bas_addr
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: vnet_bas_addr
          networkSecurityGroup: {
            id: nsgBastion.outputs.id
          }
        }
      }
    ]
  }
}

module pipBastion 'components/pip/pip.bicep' = {
  name: bas_pip_n
  params: {
    pip_n: bas_pip_n
    tags: tags
    location: location
  }
}

module bas 'components/bas/bas.bicep' = {
  name: bas_n
  params: {
    bas_n: bas_n
    bas_sku: bas_sku
    bas_enableTunneling: bas_sku == 'Basic' ? false : bas_enableTunneling
    bas_enableIpConnect: bas_sku == 'Basic' ? false : bas_enableIpConnect
    bas_enableShareableLink: bas_sku == 'Basic' ? false : bas_enableShareableLink
    enableKerberos: bas_enableKerberos
    snet_bas_id: vnetBastion.properties.subnets[0].id
    pip_id: pipBastion.outputs.id
    location: location
  }
}
