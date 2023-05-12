// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
var tags = {
  project: 'bicephub'
  env: 'dev'
}

param location string = resourceGroup().location

// ------------------------------------------------------------------------------------------------
// Bastion Configuration parameters
// ------------------------------------------------------------------------------------------------
var env ='dev'
var vnet_bas_addr = '10.10.10.0/24'

// ------------------------------------------------------------------------------------------------
// Bastion - Deploy Azure Bastion
// ------------------------------------------------------------------------------------------------
module bastionDefault '../main.bicep' = {
  name: 'bas-default-deployment'
  params: {
    vnet_bas_addr: vnet_bas_addr
    env: env
    location: location
    tags: tags
  }
}

module bastionBasic '../main.bicep' = {
  name: 'bas-basic-deployment'
  params: {
    bas_n: 'bas-basic'
    bas_sku: 'Basic'
    vnet_bas_n: 'vnet-bas-basic'
    bas_nsg_n: 'nsg-bas-basic'
    bas_pip_n: 'pip-bas-basic'
    vnet_bas_addr: vnet_bas_addr
    env: env
    location: location
    tags: tags
  }
}

module bastionStandard '../main.bicep' = {
  name: 'bas-standard-deployment'
  params: {
    bas_n: 'bas-standard'
    bas_sku: 'Standard'
    vnet_bas_n: 'vnet-bas-standard'
    bas_nsg_n: 'nsg-bas-standard'
    bas_pip_n: 'pip-bas-standard'
    vnet_bas_addr: vnet_bas_addr
    bas_enableIpConnect: false
    bas_enableKerberos: false
    bas_enableShareableLink: false
    bas_enableTunneling: false
    env: env
    location: location
    tags: tags
  }
}

module bastionStandardFull '../main.bicep' = {
  name: 'bas-standard-full-deployment'
  params: {
    bas_n: 'bas-standard-full'
    bas_sku: 'Standard'
    vnet_bas_n: 'vnet-bas-standard-full'
    bas_nsg_n: 'nsg-bas-standard-full'
    bas_pip_n: 'pip-bas-standard-full'
    vnet_bas_addr: vnet_bas_addr
    bas_enableIpConnect: true
    bas_enableKerberos: true
    bas_enableShareableLink: true
    bas_enableTunneling: true
    env: env
    location: location
    tags: tags
  }
}
