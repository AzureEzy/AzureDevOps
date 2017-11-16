# ASM2ARM - Migrate VMs not in VNet Part 1

This script is for VM's which is only in Cloudservice and not the part of any VNet. This migration approach will automatically create VNet for you in ARM Model and then migrate ASM VM's into ARM. Follow the code snippet below:

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
Get-AzureRmVMUsage -Location "East US"

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


#Validate your migration
$validate = Move-AzureService -Validate -ServiceName $serviceName `
    -DeploymentName $deploymentName -CreateNewVirtualNetwork
$validate.ValidationMessages


#Prepare your Migration
Move-AzureService -Prepare -ServiceName $serviceName `
    -DeploymentName $deploymentName -CreateNewVirtualNetwork

#Abort your Cloudservice migration if you are not good to go
Move-AzureService -Abort -ServiceName $serviceName -DeploymentName $deploymentName

#Commit your Cloudservice migration if all good.(Once you commited you can't revert it back to ASM)
Move-AzureService -Commit -ServiceName $serviceName -DeploymentName $deploymentName
```