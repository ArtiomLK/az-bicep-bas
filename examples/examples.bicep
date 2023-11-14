@description('Specifies the location for resources.')
param l_developer_sku string = 'northcentralus'

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
var env = 'dev'
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

module bastionDeveloper '../main.bicep' = {
  name: 'bas-developer-deployment'
  params: {
    vnet_bas_addr: vnet_bas_addr
    bas_sku: 'Developer'
    env: env
    location: l_developer_sku
    tags: tags
  }
}

module bastionBasic '../main.bicep' = {
  name: 'bas-basic-deployment'
  params: {
    bas_n: 'bas-basic'
    bas_sku: 'Basic'
    vnet_bas_n: 'vnet-bas-basic-${env}-${location}'
    ngs_bas_n: 'nsg-bas-basic-${env}-${location}'
    pip_bas_n: 'pip-bas-basic-${env}-${location}'
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
    vnet_bas_n: 'vnet-bas-standard-${env}-${location}'
    ngs_bas_n: 'nsg-bas-standard-${env}-${location}'
    pip_bas_n: 'pip-bas-standard-${env}-${location}'
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
    vnet_bas_n: 'vnet-bas-standard-full-${env}-${location}'
    ngs_bas_n: 'nsg-bas-standard-full-${env}-${location}'
    pip_bas_n: 'pip-bas-standard-full-${env}-${location}'
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
