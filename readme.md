# Azure Bastion

## Instructions - Create Bastion on VWAN [Hub Extension Pattern][8]

```bash
# ---
# Main Vars
# ---
sub_id='########-####-####-####-############';                          echo $sub_id          # must update
env="prod";                                                             echo $env
project="connectivity";                                                 echo $project
l="eastus2";                                                            echo $l
tags="project=$project env=$env architecture=extension pattern";        echo $tags

# ---
# BAS - NETWORK TOPOLOGY
# ---
rg_bas_n="rg-$project-bas-$env-$l";                                     echo $rg_bas_n        # must update
vnet_bas_n="vnet-$project-bas-$env-$l";                                 echo $vnet_bas_n      # must update
vnet_bas_addr="10.10.0.0/24";                                           echo $vnet_bas_addr   # must update

snet_bas_n="AzureBastionSubnet";                                        echo $snet_bas_n
snet_bas_addr="10.10.0.192/26";                                         echo $snet_bas_addr   # must update

nsg_bas_n="nsg-$project-bas-$env-$l";                                   echo $nsg_bas_n

# ---
# BAS
# ---
bas_n="bas-$project-$env-$l";                                           echo $bas_n
bas_pip="pip-$project-bas-$env-$l";                                     echo $bas_pip
bas_sku="Standard";                                                     echo $bas_sku
bas_pip_sku="Standard";                                                 echo $bas_pip_sku
bas_enable_native_client_support="true";                                echo $bas_enable_native_client_support
bas_enable_ip_based_connection="true";                                  echo $bas_enable_ip_based_connection
```

[Deploy Bastion to HUB RG or Create HUB RG if nonexistent][3]

```bash
# ------------------------------------------------------------------------------------------------
# Create BAS RG
# ------------------------------------------------------------------------------------------------
az group create \
--subscription $sub_id \
--name $rg_bas_n \
--location $l \
--tags $tags

# ------------------------------------------------------------------------------------------------
# Create BAS NSG
# ------------------------------------------------------------------------------------------------
az network nsg create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name $nsg_bas_n \
--location $l \
--tags $tags

# Bastion NSG Rules
# Inbound/Ingress
# AllowHttpsInBound
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name AllowHttpsInBound \
--nsg-name $nsg_bas_n \
--priority 120 \
--destination-port-ranges 443 \
--protocol TCP \
--source-address-prefixes Internet \
--destination-address-prefixes "*" \
--access Allow
# AllowGatewayManagerInbound
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name AllowGatewayManagerInbound \
--direction Inbound \
--nsg-name $nsg_bas_n \
--priority 130 \
--destination-port-ranges 443 \
--protocol TCP \
--source-address-prefixes GatewayManager \
--destination-address-prefixes "*" \
--access Allow
# AllowAzureLoadBalancerInbound
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name AllowAzureLoadBalancerInbound \
--direction Inbound \
--nsg-name $nsg_bas_n \
--priority 140 \
--destination-port-ranges 443 \
--protocol TCP \
--source-address-prefixes AzureLoadBalancer \
--destination-address-prefixes "*" \
--access Allow
# AllowBastionHostCommunication
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name AllowBastionHostCommunication \
--direction Inbound \
--nsg-name $nsg_bas_n \
--priority 150 \
--destination-port-ranges 8080 5701 \
--protocol "*" \
--source-address-prefixes VirtualNetwork \
--destination-address-prefixes VirtualNetwork \
--access Allow
# OutBound/Egress
# AllowSshRdpOutbound
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name AllowSshRdpOutbound \
--priority 100 \
--destination-port-ranges 22 3389 \
--protocol "*" \
--source-address-prefixes "*" \
--destination-address-prefixes VirtualNetwork \
--access Allow \
--nsg-name $nsg_bas_n \
--direction Outbound
# AllowAzureCloudOutbound
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name AllowAzureCloudOutbound \
--priority 110 \
--destination-port-ranges 443 \
--protocol TCP \
--source-address-prefixes "*" \
--destination-address-prefixes AzureCloud \
--access Allow \
--nsg-name $nsg_bas_n \
--direction Outbound
# AllowBastion:Communication
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name AllowBastionCommunication \
--priority 120 \
--destination-port-ranges 8080 5701 \
--protocol "*" \
--source-address-prefixes VirtualNetwork \
--destination-address-prefixes VirtualNetwork \
--access Allow \
--nsg-name $nsg_bas_n \
--direction Outbound
# AllowGetSessionInformation
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name AllowGetSessionInformation \
--priority 130 \
--destination-port-ranges 80 \
--protocol "*" \
--source-address-prefixes "*" \
--destination-address-prefixes Internet \
--access Allow \
--nsg-name $nsg_bas_n \
--direction Outbound

# ------------------------------------------------------------------------------------------------
# Create Bastion VNET
# ------------------------------------------------------------------------------------------------
# Bastion vnet
az network vnet create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name $vnet_bas_n \
--address-prefixes $vnet_bas_addr \
--location $l \
--tags $tags

# Bastion snet
az network vnet subnet create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--vnet-name $vnet_bas_n \
--name $snet_bas_n \
--address-prefixes $snet_bas_addr \
--network-security-group $nsg_bas_n

# ------------------------------------------------------------------------------------------------
# Create PIP
# ------------------------------------------------------------------------------------------------
# Bastion Public IP
az network public-ip create \
--subscription $sub_id \
--resource-group $rg_bas_n \
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
--resource-group $rg_bas_n \
--name $bas_n \
--public-ip-address $bas_pip \
--vnet-name $vnet_bas_n \
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
vnet1_rg_n="rg-dev-eastus";                                         echo $vnet1_rg_n         # must update
vnet1_n="vnet-dev-eastus";                                          echo $vnet1_n            # must update
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
--name $bas_n \
--resource-group $rg_bas_n \
--target-resource-id "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-name/providers/Microsoft.Compute/virtualMachines/vm-name" \
--target-ip-address 10.10.10.10 \
--disable-gateway  # optional
```

## Notes

- [snet size + /26. Subnet size must be /26 or larger (/25, /24 etc.)][1]

## Additional Resources

- Azure Bastion
- [MS | Learn | Connect to a VM using a native client][2]
- [MS | Learn | Working with NSG access and Azure Bastion][10]
- [MS | Learn | Azure Virtual Network frequently asked questions (FAQ) | What address ranges can I use in my VNets?][5]
- [MS | Learn | VNet peering, VWAN and Azure Bastion][6]
- [StackOverflow | ArtiomLK | Is Azure Bastion able to connect via transitive peering?][7]
- [MS | Tutorial: Protect your Bastion host with Azure DDoS protection][9]

[1]: https://learn.microsoft.com/en-us/azure/bastion/configuration-settings#subnet
[2]: https://learn.microsoft.com/EN-US/azure/bastion/connect-native-client-windows
[3]: https://github.com/ArtiomLK/commands/blob/main/bash/readme.md#create-rg
[4]: https://github.com/ArtiomLK/commands/blob/main/bash/readme.md#create-vnet-peering
[5]: https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-faq#what-address-ranges-can-i-use-in-my-vnets
[6]: https://learn.microsoft.com/en-us/azure/bastion/vnet-peering
[7]: https://stackoverflow.com/a/75980971/5212904
[8]: https://learn.microsoft.com/en-us/azure/architecture/guide/networking/private-link-virtual-wan-dns-virtual-hub-extension-pattern
[9]: https://learn.microsoft.com/en-us/azure/bastion/tutorial-protect-bastion-host-ddos
[10]: https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg
