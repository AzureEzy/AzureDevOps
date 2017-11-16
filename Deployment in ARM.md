# Deployment of a Virtual machine using AzureRM PowerShell modules.

## Create a resource group.

```powershell
New-AzureRmResourceGroup -Name myResourceGroup -Location EastUS
```

## Create a subnet configuration

```powershell
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name mySubnet -AddressPrefix *.*.*.*/*
```

## Create a virtual network

```powershell
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName myResourceGroup -Location EastUS `
    -Name MYvNET -AddressPrefix *.*.*.*/* -Subnet $subnetConfig
```

## Create a public IP address and specify a DNS name

```powershell
$pip = New-AzureRmPublicIpAddress -ResourceGroupName myResourceGroup -Location EastUS `
    -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "mypublicdns$(Get-Random)"
```

## Create an inbound network security group rule for port 3389

```powershell
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRDP  -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow
```

## Create an inbound network security group rule for port 80

```powershell
$nsgRuleWeb = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleWWW  -Protocol Tcp `
    -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 80 -Access Allow
```

## Create a network security group

```powershell
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName myResourceGroup -Location EastUS `
    -Name myNetworkSecurityGroup -SecurityRules $nsgRuleRDP,$nsgRuleWeb

```

## Create a virtual network card and associate with public IP address and NSG

```powershell
$nic = New-AzureRmNetworkInterface -Name myNic -ResourceGroupName myResourceGroup -Location EastUS `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
```

## Define a credential object

```powershell
$cred = Get-Credential
```

## Create a virtual machine configuration

```powershell
$vmConfig = New-AzureRmVMConfig -VMName myVM -VMSize Standard_DS14 | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName myVM -Credential $cred | `
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id

    New-AzureRmVM -ResourceGroupName myResourceGroup -Location EastUS -VM $vmConfig
```