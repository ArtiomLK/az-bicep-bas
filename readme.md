# Azure Bastion

## Instructions

```bash
# ---
# Main Vars
# ---
sub_id='########-####-####-####-############';                          echo $sub_id          # must update
app="alz-bas";                                                          echo $app
env="dev";                                                              echo $env
l="eastus";                                                             echo $l
tags="project=bicephub env=$env architecture=topology";                 echo $tags

# ---
# HUB - NETWORK TOPOLOGY
# ---
rg_hub_n="rg-hub-$env-$l";                                              echo $rg_hub_n        # must update
vnet_hub_n="vnet-hub-$env-$l";                                          echo $vnet_hub_n      # must update
vnet_hub_pre="10.10";                                                   echo $vnet_hub_pre    # must update
vnet_hub_addr="$vnet_hub_pre.0.0/24";                                   echo $vnet_hub_addr   # must update

# ---
# Bastion
# ---
snet_n_bas="AzureBastionSubnet";                                        echo $snet_n_bas
snet_addr_bas="$vnet_hub_pre.0.192/26";                                 echo $snet_addr_bas   # must update
nsg_n_bastion="nsg-$app-$env-$l";                                       echo $nsg_n_bastion
bas_n="bas-$app-$env-$l";                                               echo $bas_n
bas_pip="pip-bas-$app-$env-$l";                                         echo $bas_pip
bas_sku="Standard";                                                     echo $bas_sku
bas_pip_sku="Standard";                                                 echo $bas_pip_sku
bas_enable_native_client_support="true";                                echo $bas_enable_native_client_support
bas_enable_ip_based_connection="true";                                  echo $bas_enable_ip_based_connection
```

[Deploy Bastion to HUB RG or Create HUB RG if nonexistent][3]

```bash
# ------------------------------------------------------------------------------------------------
# Reference HUB vNet - HUB vNet should be already created, otherwise uncomment and create the HUB vnet
# ------------------------------------------------------------------------------------------------
# az network vnet create \
# --subscription $sub_id \
# --name $vnet_hub_n \
# --resource-group $rg_hub_n \
# --address-prefixes $vnet_hub_addr \
# --location $l \
# --tags $tags

# ------------------------------------------------------------------------------------------------
# Create bastion NSG
# ------------------------------------------------------------------------------------------------
az network nsg create \
--subscription $sub_id \
--resource-group $rg_hub_n \
--name $nsg_n_bastion \
--location $l \
--tags $tags

# Bastion NSG Rules
# Inbound/Ingress
# AllowHttpsInBound
az network nsg rule create \
--name AllowHttpsInBound \
--resource-group $rg_hub_n \
--nsg-name $nsg_n_bastion \
--priority 120 \
--destination-port-ranges 443 \
--protocol TCP \
--source-address-prefixes Internet \
--destination-address-prefixes "*" \
--access Allow
# AllowGatewayManagerInbound
az network nsg rule create \
--name AllowGatewayManagerInbound \
--direction Inbound \
--resource-group $rg_hub_n \
--nsg-name $nsg_n_bastion \
--priority 130 \
--destination-port-ranges 443 \
--protocol TCP \
--source-address-prefixes GatewayManager \
--destination-address-prefixes "*" \
--access Allow
# AllowAzureLoadBalancerInbound
az network nsg rule create \
--name AllowAzureLoadBalancerInbound \
--direction Inbound \
--resource-group $rg_hub_n \
--nsg-name $nsg_n_bastion \
--priority 140 \
--destination-port-ranges 443 \
--protocol TCP \
--source-address-prefixes AzureLoadBalancer \
--destination-address-prefixes "*" \
--access Allow
# AllowBastionHostCommunication
az network nsg rule create \
--name AllowBastionHostCommunication \
--direction Inbound \
--resource-group $rg_hub_n \
--nsg-name $nsg_n_bastion \
--priority 150 \
--destination-port-ranges 8080 5701 \
--protocol "*" \
--source-address-prefixes VirtualNetwork \
--destination-address-prefixes VirtualNetwork \
--access Allow
# OutBound/Egress
# AllowSshRdpOutbound
az network nsg rule create \
--priority 100 \
--name AllowSshRdpOutbound \
--destination-port-ranges 22 3389 \
--protocol "*" \
--source-address-prefixes "*" \
--destination-address-prefixes VirtualNetwork \
--access Allow \
--nsg-name $nsg_n_bastion \
--resource-group $rg_hub_n \
--direction Outbound
# AllowAzureCloudOutbound
az network nsg rule create \
--priority 110 \
--name AllowAzureCloudOutbound \
--destination-port-ranges 443 \
--protocol TCP \
--source-address-prefixes "*" \
--destination-address-prefixes AzureCloud \
--access Allow \
--nsg-name $nsg_n_bastion \
--resource-group $rg_hub_n \
--direction Outbound
# AllowBastion:Communication
az network nsg rule create \
--priority 120 \
--name AllowBastionCommunication \
--destination-port-ranges 8080 5701 \
--protocol "*" \
--source-address-prefixes VirtualNetwork \
--destination-address-prefixes VirtualNetwork \
--access Allow \
--nsg-name $nsg_n_bastion \
--resource-group $rg_hub_n \
--direction Outbound
# AllowGetSessionInformation
az network nsg rule create \
--priority 130 \
--name AllowGetSessionInformation \
--destination-port-ranges 80 \
--protocol "*" \
--source-address-prefixes "*" \
--destination-address-prefixes Internet \
--access Allow \
--nsg-name $nsg_n_bastion \
--resource-group $rg_hub_n \
--direction Outbound

# ------------------------------------------------------------------------------------------------
# Create Bastion SNET
# ------------------------------------------------------------------------------------------------
# HUB Bastion Subnet
az network vnet subnet create \
--subscription $sub_id \
--resource-group $rg_hub_n \
--vnet-name $vnet_hub_n \
--name $snet_n_bas \
--address-prefixes $snet_addr_bas \
--network-security-group $nsg_n_bastion

# ------------------------------------------------------------------------------------------------
# Create PIP
# ------------------------------------------------------------------------------------------------
# Bastion Public IP
az network public-ip create \
--subscription $sub_id \
--resource-group $rg_hub_n \
--name $bas_pip \
--sku $bas_pip_sku \
--zone 1 2 3 \
--location $l \
--tags $tags

# ------------------------------------------------------------------------------------------------
# Create Bastion
# ------------------------------------------------------------------------------------------------
# Bastion (it takes a while go get some coffee)
az network bastion create \
--subscription $sub_id \
--resource-group $rg_hub_n \
--name $bas_n \
--public-ip-address $bas_pip \
--vnet-name $vnet_hub_n \
--location $l \
--sku $bas_sku \
--enable-ip-connect $bas_enable_ip_based_connection \
--enable-tunneling $bas_enable_native_client_support \
--tags $tags
```

[Create vnet peering to access vms][4]

```bash
# ------------------------------------------------------------------------------------------------
# Create vnet peering
# ------------------------------------------------------------------------------------------------
# VNET_1 Variables
vnet1_rg_n="rg-hub-dev-eastus";                             echo $vnet1_rg_n
vnet1_n="vnet-hub-dev-eastus";                              echo $vnet1_n
```

## Connect to a VM using a native client

- [MS | Learn | Connect to a VM using a native client][2]

```bash
az account show

az network bastion rdp \
--name "<BastionName>" \
--resource-group "<BastionResourceGroupName>" \
--target-resource-id "<VMResourceId>" \
--target-ip-address <priv-ip> \
--disable-gateway  # optional

az network bastion rdp \
--name "bas-alz-bas-dev-eastus" \
--resource-group "rg-hub-dev-eastus" \
--target-resource-id "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-name/providers/Microsoft.Compute/virtualMachines/vm-name" \
--target-ip-address 10.10.10.10 \
--disable-gateway  # optional
```

## Notes

- [snet size + /26. Subnet size must be /26 or larger (/25, /24 etc.)][1]

## Additional Resources

- Azure Bastion
- [MS | Learn | Connect to a VM using a native client][2]
- [MS | Learn | Azure Virtual Network frequently asked questions (FAQ) | What address ranges can I use in my VNets?][5]
- [MS | Learn | VNet peering, VWAN and Azure Bastion][6]
- [StackOverflow | ArtiomLK | Is Azure Bastion able to connect via transitive peering?][7]

[1]: https://learn.microsoft.com/en-us/azure/bastion/configuration-settings#subnet
[2]: https://learn.microsoft.com/EN-US/azure/bastion/connect-native-client-windows
[3]: https://github.com/ArtiomLK/commands/blob/main/bash/readme.md#create-rg
[4]: https://github.com/ArtiomLK/commands/blob/main/bash/readme.md#create-vnet-peering
[5]: https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-faq#what-address-ranges-can-i-use-in-my-vnets
[6]: https://learn.microsoft.com/en-us/azure/bastion/vnet-peering
[7]: https://stackoverflow.com/a/75980971/5212904
