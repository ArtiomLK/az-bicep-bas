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
param bas_n string = 'bas-${env}-${location}'
@allowed([
  'Developer'
  'Basic'
  'Standard'
])
param bas_sku string = 'Basic'
param bas_enableTunneling bool = false
param bas_enableIpConnect bool = false
param bas_enableShareableLink bool = false
param bas_enableKerberos bool = false
param vnet_bas_n string = 'vnet-bas-${env}-${location}'
param vnet_bas_addr string
param ngs_bas_n string = 'nsg-bas-${env}-${location}'
param pip_bas_n string = 'pip-bas-${env}-${location}'

// ------------------------------------------------------------------------------------------------
// Bastion - Deploy Azure Bastion
// ------------------------------------------------------------------------------------------------
module nsgBastion 'modules/nsg/nsgBas.bicep' = {
  name: ngs_bas_n
  params: {
    tags: tags
    location: location
    nsgName: ngs_bas_n
  }
}

resource vnetBastion 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnet_bas_n
  tags: tags
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_bas_addr
      ]
    }
    subnets: bas_sku == 'Developer' ? [] : [
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

module pipBastion 'modules/pip/pip.bicep' = if (bas_sku != 'Developer') {
  name: pip_bas_n
  params: {
    tags: tags
    location: location
    pip_n: pip_bas_n
  }
}

module bas 'modules/bas/bas.bicep' = {
  name: bas_n
  params: {
    tags: tags
    location: location
    bas_n: bas_n
    bas_sku: bas_sku
    vnet_id: vnetBastion.id
    bas_enableTunneling: bas_enableTunneling
    bas_enableIpConnect: bas_enableIpConnect
    bas_enableShareableLink:bas_enableShareableLink
    enableKerberos: bas_enableKerberos
    snet_bas_id: bas_sku == 'Developer' ? '' : vnetBastion.properties.subnets[0].id
    pip_id: bas_sku == 'Developer' ? '' : pipBastion.outputs.id
  }
}

output vnet_id string = vnetBastion.id
