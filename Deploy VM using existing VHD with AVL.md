# Deploy Azure virtual machine using existing VHD with an availability set

Below code snippet deploys a new AzureVM

```powershell
$Region = "East US"
$resourcegroupName = 'azureprep'
$VNetName = 'azprepnet'
$VNICName = 'azprepVMNIC'
$VMName = 'testvm1'
$AvailabilitySetName = 'azprepavset'
$osDiskUri = "https://azprepstore.blob.core.windows.net/vhds/azprepubuntu120171106083241.vhd"

 $VNET = Get-AzureRmVirtualNetwork -Name $azprepnet -ResourceGroupName $resourcegroupName
  $VNIC = Get-AzureRmNetworkInterface -Name $VNICName -ResourceGroupName $resourcegroupName

 # VM settings
 $AVSetID = Get-AzureRmAvailabilitySet -ResourceGroupName azureprep -Name azprepavset | Select-Object -ExpandProperty ID
 $VM = New-AzureRmVMConfig -VMName $VMName -VMSize "Standard_A2" -AvailabilitySetId $AVSetID
  $VM = Set-AzureRmVMOSDisk -VM $VM -Name $(split-path -path ([uri]$osDiskUri) -Leaf) -VhdUri $osDiskUri -CreateOption attach -Windows

 # Network Interfaces
 $VM = Add-AzureRmVMNetworkInterface -VM $VM -Id $VNIC.Id

 # Creating VM
 New-AzureRMVM -ResourceGroupName $resourcegroupName -Location $Region -VM $VM -Verbose
```