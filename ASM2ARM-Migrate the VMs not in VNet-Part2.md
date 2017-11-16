# ASM2ARM - Migrate VMs not in VNet Part 2

The below script snippet is applicable for VMs which are only in a Cloudservice and not part of any VNet. In this migration approach you have to migrate ASM VMs to your desired VNet in ARM. That Vnet should already exist in ARM.

```powershell
#Login to ARM model
Login-AzureRmAccount

#Get all azure subscription which are attached with your account
Get-AzureRMSubscription | Sort-Object -Property Name | Select-Object -Property Name

#Select a subscription where action need to perform
Select-AzureRmSubscription –SubscriptionName "Visual Studio Dev Essentials"

#Register resource manager Provider(It will take less than 5 mins)
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.ClassicInfrastructureMigrate

#Get confirmed registration done or not.
Get-AzureRmResourceProvider -ProviderNamespace Microsoft.ClassicInfrastructureMigrate

#Check resources usage in resource manager.(Raise an request with MS if you need more)
Get-AzureRmVMUsage -Location "Southeast Asia"

#Login to ASM Model
Add-AzureAccount

#Get all azure subscription which are attached with your account
Get-AzureSubscription | Sort-Object -Property SubscriptionName | Select-Object -Property SubscriptionName

#Select a subscription where action need to perform
Select-AzureSubscription –SubscriptionName "Visual Studio Dev Essentials"


#Get Cloudservice name where migration need to perform.
Get-AzureService | Format-Table -Property Servicename

#Define variable with Cloudservice name
$serviceName = "ASM2ARM-CSVM"
    $deployment = Get-AzureDeployment -ServiceName $serviceName
    $deploymentName = $deployment.DeploymentName

#Migrate VM's in existing VNet in ARM Model
$existingVnetRGName = "ASM2ARMCS-Vnet-RG"
$vnetName = "ASM2ARMCSVnet"
$subnetName = "FrontEnd"

#Validate your migration
$validate = Move-AzureService -Validate -ServiceName $serviceName `
    -DeploymentName $deploymentName -UseExistingVirtualNetwork -VirtualNetworkResourceGroupName $existingVnetRGName -VirtualNetworkName $vnetName -SubnetName $subnetName
$validate.ValidationMessages

#Prepare your Migration
Move-AzureService -Prepare -ServiceName $serviceName -DeploymentName $deploymentName `
    -UseExistingVirtualNetwork -VirtualNetworkResourceGroupName $existingVnetRGName `
    -VirtualNetworkName $vnetName -SubnetName $subnetName


#Abort your Cloudservice migration if you are not good to go
Move-AzureService -Abort -ServiceName $serviceName -DeploymentName $deploymentName

#Commit your Cloudservice migration if all good.(Once you commited you can't revert it back to ASM)
Move-AzureService -Commit -ServiceName $serviceName -DeploymentName $deploymentName

```

