# Azure Bastion

## Instructions - Create Bastion for VWAN as [Hub Extension Pattern][8]

```bash
# ---
# Main Vars
# ---
sub_id='########-####-####-####-############';                          echo $sub_id          # must update
env="prod";                                                             echo $env
project="connectivity";                                                 echo $project
l="eastus2";                                                            echo $l
tags="project=$project env=$env architecture=extension-pattern";        echo $tags

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

# ---
# Spoke VM - NETWORK TOPOLOGY
# ---
snet_spoke_i_n="snet-spoke-0";                                          echo $snet_spoke_i_n
snet_spoke_i_addr="10.10.0.128/26";                                     echo $snet_spoke_i_addr   # must update

nsg_sopke_i_n="nsg-$project-spoke-0-$env-$l";                           echo $nsg_sopke_i_n

# ---
# Spoke VM
# ---
vm_spoke_admin_n="artiomlk";                                            echo $vm_spoke_admin_n

# Windows
vm_spoke_win_n="vm-spoke-win-0";                                        echo $vm_spoke_win_n
vm_spoke_win_img="Win2022AzureEditionCore";                             echo $vm_spoke_win_img

# Linux
vm_spoke_lin_n="vm-spoke-lin-0-$env-$l";                                echo $vm_spoke_lin_n
vm_spoke_lin_img="Ubuntu2204";                                          echo $vm_spoke_lin_img

# ------------------------------------------------------------------------------------------------
# DEPLOYMENT
# ------------------------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------------------------
# Create BAS NSG Rules
# ------------------------------------------------------------------------------------------------
# Inbound/Ingress
# AllowHttpsInBound
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--nsg-name $nsg_bas_n \
--name AllowHttpsInBound \
--priority 120 \
--protocol TCP \
--destination-port-ranges 443 \
--source-address-prefixes Internet \
--destination-address-prefixes "*" \
--access Allow

# AllowGatewayManagerInbound
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--nsg-name $nsg_bas_n \
--name AllowGatewayManagerInbound \
--direction Inbound \
--priority 130 \
--protocol TCP \
--destination-port-ranges 443 \
--source-address-prefixes GatewayManager \
--destination-address-prefixes "*" \
--access Allow

# AllowAzureLoadBalancerInbound
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--nsg-name $nsg_bas_n \
--name AllowAzureLoadBalancerInbound \
--direction Inbound \
--priority 140 \
--protocol TCP \
--destination-port-ranges 443 \
--source-address-prefixes AzureLoadBalancer \
--destination-address-prefixes "*" \
--access Allow

# AllowBastionHostCommunication
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--nsg-name $nsg_bas_n \
--name AllowBastionHostCommunication \
--direction Inbound \
--priority 150 \
--protocol "*" \
--destination-port-ranges 8080 5701 \
--source-address-prefixes VirtualNetwork \
--destination-address-prefixes VirtualNetwork \
--access Allow

# OutBound/Egress
# AllowSshRdpOutbound
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--nsg-name $nsg_bas_n \
--name AllowSshRdpOutbound \
--direction Outbound \
--priority 100 \
--protocol "*" \
--destination-port-ranges 22 3389 \
--source-address-prefixes "*" \
--destination-address-prefixes VirtualNetwork \
--access Allow

# AllowAzureCloudOutbound
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--nsg-name $nsg_bas_n \
--name AllowAzureCloudOutbound \
--direction Outbound \
--priority 110 \
--protocol TCP \
--destination-port-ranges 443 \
--source-address-prefixes "*" \
--destination-address-prefixes AzureCloud \
--access Allow

# AllowBastion:Communication
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--nsg-name $nsg_bas_n \
--name AllowBastionCommunication \
--direction Outbound \
--priority 120 \
--protocol "*" \
--destination-port-ranges 8080 5701 \
--source-address-prefixes VirtualNetwork \
--destination-address-prefixes VirtualNetwork \
--access Allow

# AllowGetSessionInformation
az network nsg rule create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--nsg-name $nsg_bas_n \
--name AllowGetSessionInformation \
--direction Outbound \
--priority 130 \
--protocol "*" \
--destination-port-ranges 80 \
--source-address-prefixes "*" \
--destination-address-prefixes Internet \
--access Allow

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

## Create Spoke VMs if required

```bash
az network nsg create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name $nsg_sopke_i_n \
--location $l \
--tags $tags

# Spoke snet
az network vnet subnet create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--vnet-name $vnet_bas_n \
--name $snet_spoke_i_n \
--address-prefixes $snet_spoke_i_addr \
--network-security-group $nsg_bas_n

# Windows
az vm create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name $vm_spoke_win_n \
--image $vm_spoke_win_img \
--vnet-name $vnet_bas_n \
--subnet $snet_spoke_i_n \
--public-ip-address "" \
--admin-username $vm_spoke_admin_n \
--tags $tags

# Linux
az vm create \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name $vm_spoke_lin_n \
--image $vm_spoke_lin_img \
--vnet-name $vnet_bas_n \
--subnet $snet_spoke_i_n \
--public-ip-address "" \
--admin-username $vm_spoke_admin_n \
--tags $tags
```

## Connect to a VM using a native client

### Validate Connection to Bastion

```bash
# Print Bastion Public IP
az network public-ip show \
--subscription $sub_id \
--resource-group $rg_bas_n \
--name $bas_pip \
--query ipAddress \
--output tsv
```

```PowerShell
# TEST Connectivity To BASTION
Test-NetConnection "BAS_PUBPLIC_IP" -Port 443 -InformationLevel "Detailed"
```

### RDP to Spoke-VM through Bastion

- [MS | Learn | Connect to a VM using a native client][2]

```bash
# Prerequisites
az upgrade
az account set --subscription '########-####-####-####-############'

az network bastion rdp \
--name "<BastionName>" \
--resource-group "<BastionResourceGroupName>" \
--target-resource-id "<VMResourceId>" \
--target-ip-address <priv-ip> \
--disable-gateway  # optional

az network bastion rdp \
--name $bas_n \
--resource-group $rg_bas_n \
--target-resource-id "/subscriptions/########-####-####-####-############/resourceGroups/rg-name/providers/Microsoft.Compute/virtualMachines/vm-name" \
--target-ip-address 10.10.10.10 \
--disable-gateway  # optional
```

## Notes

- [snet size + /26. Subnet size must be /26 or larger (/25, /24 etc.)][1]
- [When you configure Azure Bastion using the Basic SKU, two instances are created. If you use the Standard SKU, you can specify the number of instances (with a minimum of two instances).][3]
- [each instance can support 20 concurrent RDP connections and 40 concurrent SSH connections for medium workloads (see Azure subscription limits and quotas for more information). The number of connections per instances depends on what actions you're taking when connected to the client VM. For example, if you're doing something data intensive, it creates a larger load for the instance to process. Once the concurrent sessions are exceeded, another scale unit (instance) is required.][3]

## TroubleShoot

```bash
# Issue
Exception in thread Thread-1 (_start_tunnel):
Traceback (most recent call last):
  File "threading.py", line 1016, in _bootstrap_inner
  File "threading.py", line 953, in run
  File "C:\Users\artiomlk\.azure\cliextensions\bastion\azext_bastion\custom.py", line 335, in _start_tunnel
    tunnel_server.start_server()
  File "C:\Users\artiomlk\.azure\cliextensions\bastion\azext_bastion\tunnel.py", line 194, in start_server
    self._listen()
  File "C:\Users\artiomlk\.azure\cliextensions\bastion\azext_bastion\tunnel.py", line 123, in _listen
    auth_token = self._get_auth_token()
  File "C:\Users\artiomlk\.azure\cliextensions\bastion\azext_bastion\tunnel.py", line 112, in _get_auth_token
    self.last_token = response_json["authToken"]
KeyError: 'authToken'

# Solution
# Do not include the --subscription flag in the `az network bastion rdp` command and set the subscription id using
az account set --subscription '########-####-####-####-############'
```

- [GH | ArtiomLK | Useful Bash Commands][11]

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
[3]: https://learn.microsoft.com/en-us/azure/bastion/configuration-settings#instance
[4]: https://github.com/ArtiomLK/commands/blob/main/bash/readme.md#create-vnet-peering
[5]: https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-faq#what-address-ranges-can-i-use-in-my-vnets
[6]: https://learn.microsoft.com/en-us/azure/bastion/vnet-peering
[7]: https://stackoverflow.com/a/75980971/5212904
[8]: https://learn.microsoft.com/en-us/azure/architecture/guide/networking/private-link-virtual-wan-dns-virtual-hub-extension-pattern
[9]: https://learn.microsoft.com/en-us/azure/bastion/tutorial-protect-bastion-host-ddos
[10]: https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg
[11]: https://github.com/ArtiomLK/commands/blob/main/bash/readme.md#bash
