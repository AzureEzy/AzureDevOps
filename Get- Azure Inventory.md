# Get Azure Inventoy

```powershell
####################################################################################################################################################
#                  Azure Inventory Script
#
#
#The following Azure Resources are gathered by this script:
#   -Resouce Groups
#   -Virtual Networks
#   -Network Security Groups
#   -Subnets
#   -Virtual Machines
#   -Vnics
#   -Storage Accounts
#   -Storage Blobs
#   -
#
####################################################################################################################################################

$Directory = New-Item c:\AzureInventory -type directory

Login-AzureRmAccount -SubscriptionName "DR"


#****************************************************************************************************************************************************
#Function for converting csv files into one Excel Sheet written by Microsoft PowerShell MVP Boe Prox - http://learn-powershell.net/author/boeprox/
#****************************************************************************************************************************************************


#****************************************************************************************************************************************************
Function Release-Ref ($ref)
 {
 ([System.Runtime.InteropServices.Marshal]::ReleaseComObject(
 [System.__ComObject]$ref) -gt 0)
 [System.GC]::Collect()
 [System.GC]::WaitForPendingFinalizers()
 }

Function ConvertCSV-ToExcel
 {
 <#
 .SYNOPSIS
 Converts one or more CSV files into an excel file.

.DESCRIPTION
 Converts one or more CSV files into an excel file. Each CSV file is imported into its own worksheet with the name of the
 file being the name of the worksheet.

.PARAMETER inputfile
 Name of the CSV file being converted

.PARAMETER output
 Name of the converted excel file

.EXAMPLE 
 Get-ChildItem *.csv | ConvertCSV-ToExcel -output ‘report.xlsx’

.EXAMPLE 
 ConvertCSV-ToExcel -inputfile ‘file.csv’ -output ‘report.xlsx’

.EXAMPLE 
 ConvertCSV-ToExcel -inputfile @(“test1.csv”,”test2.csv”) -output ‘report.xlsx’

.NOTES
 Author: Boe Prox
 Date Created: 01SEPT210
 Last Modified:

#>

 [CmdletBinding(
                SupportsShouldProcess = $True,
                ConfirmImpact = ‘low’,
                DefaultParameterSetName = ‘file’
                )]
 Param (
    [Parameter( ValueFromPipeline=$True,
                Position=0,
                Mandatory=$True,
                HelpMessage="Name of CSV/s to import")]
    [ValidateNotNullOrEmpty()]
    [array]$inputfile,

    [Parameter(ValueFromPipeline=$False,
                Position=1,
                Mandatory=$True,
                HelpMessage="Name of excel file output")]
    [ValidateNotNullOrEmpty()]
    [string]$output
 )

Begin {
    #Configure regular expression to match full path of each file
    [regex]$regex = “^\w\:\\”

    #Find the number of CSVs being imported
    $count = ($inputfile.count -1)

    #Create Excel Com Object
    $excel = new-object -com excel.application

    #Disable alerts 
    $excel.DisplayAlerts = $False

    #Show Excel application
    $excel.Visible = $False

    #Add workbook
    $workbook = $excel.workbooks.Add()

    #Remove other worksheets
    $workbook.worksheets.Item(2).delete()
    #After the first worksheet is removed,the next one takes its place
    $workbook.worksheets.Item(2).delete()

    #Define initial worksheet number
    $i = 1
 }

Process {
    ForEach ($input in $inputfile) {
        #If more than one file, create another worksheet for each file
        If ($i -gt 1) {
            $workbook.worksheets.Add() | Out-Null
        }
        #Use the first worksheet in the workbook (also the newest created worksheet is always 1)
        $worksheet = $workbook.worksheets.Item(1)
        #Add name of CSV as worksheet name
        $worksheet.name = “$((GCI $input).basename)”

        #Open the CSV file in Excel, must be converted into complete path if no already done
        If ($regex.ismatch($input)) {
            $tempcsv = $excel.Workbooks.Open($input)
        }
        ElseIf ($regex.ismatch(“$($input.fullname)”)) {
            $tempcsv = $excel.Workbooks.Open(“$($input.fullname)”)
        }
        Else {
            $tempcsv = $excel.Workbooks.Open(“$($Directory)\$input”)
        }
        $tempsheet = $tempcsv.Worksheets.Item(1)
        #Copy contents of the CSV file
        $tempSheet.UsedRange.Copy() | Out-Null
        #Paste contents of CSV into existing workbook
        $worksheet.Paste()

        #Close temp workbook
        $tempcsv.close()

        #Select all used cells
        $range = $worksheet.UsedRange

        #Autofit the columns
        $range.EntireColumn.Autofit() | out-null
        $i++
 }
 }

End {
    #Save spreadsheet
    $workbook.saveas(“$Directory\$output”)

    Write-Host -Fore Green “File saved to $Directory\$output”

#Close Excel
    $excel.quit()

#Release processes for Excel
    $a = Release-Ref($range)
    }
 }
#****************************************************************************************************************************************************

#-----------------------------------------------------------
#         Resource Groups
#-----------------------------------------------------------
$rgGroups = Get-AzureRmResourceGroup |select ResourceGroupName,Location
#CSV Exports Resource Groups
$csvrgGroupspath = $Directory.FullName + "\ResourceGroups.csv"
$csvrgGroups = $rgGroups  | Export-Csv $csvrgGroupspath -NoTypeInformation

#-----------------------------------------------------------
#         Virtual Network
#-----------------------------------------------------------
$vnetworks = Get-AzureRmVirtualNetwork
$virtualNetworks=foreach($vnetwork in $vnetworks){

    $Subs = $vnetwork.Subnets
    $subnets=foreach($sub in $subs){
                $NetworkSecurityGroup = Get-AzureRmNetworkSecurityGroup | where {$_.Id -eq $sub.NetworkSecurityGroup.Id}
                $RouteTable = Get-AzureRmRouteTable | where {$_.Id -eq $sub.RouteTable.Id}
                $Vnics = Get-AzureRmNetworkInterface |Where {$_.IpConfigurations.Subnet.Id -eq $sub.id}
                $virtualNICS =foreach($Vnic in $Vnics){
                    $VM = Get-azureRMVM | Where {$_.Id -eq $Vnic.VirtualMachine.Id}
                    #$vnic
                    [pscustomobject]@{
                        VirtualNetwork = $vnetwork.Name
                        VNResourceGroup=$vnetwork.ResourceGroupName
                        VNAddressPrefixes = $vnetwork.AddressSpace.AddressPrefixes -join "**"
                        VNDNS = $vnetwork.DhcpOptions.DnsServers -join "**"
                        SubnetName=$sub.Name
                        SubnetAddressprefix=$sub.AddressPrefix
                        SubnetNetWorkSecuritygroup=$NetworkSecurityGroup.Name
                        SubnetRouteTable=$RouteTable.Name
                        VMName = $VM.Name
                        VMResourceGroupName = $VM.ResourceGroupName
                        VnicName = $Vnic.Name
                        VnicPrivateIpAddress = $Vnic.IpConfigurations.PrivateIpAddress
                        VnicPrivateIpAllocationMethod = $Vnic.IpConfigurations.PrivateIpAllocationMethod
                    }
                }
                #Subnet
                [pscustomobject]@{
                    SubnetName=$sub.Name
                    Addressprefix=$sub.AddressPrefix
                    NetWorkSecuritygroup=$NetworkSecurityGroup.Name
                    RouteTable=$RouteTable.Name
                    Vnics = $virtualNICS
                }
            }

    [pscustomobject]@{
        NetworkName = $vnetwork.Name
        ResourceGroup=$vnetwork.ResourceGroupName
        AddressPrefixes = $vnetwork.AddressSpace.AddressPrefixes
        DNS = $vnetwork.DhcpOptions.DnsServers
        Subnets = $subnets
        Vnics = $virtualNICS
    }

    $csvVirtualNetworkpath = $Directory.FullName + "\" + $vnetwork.Name + "-Network.csv"
    $csvVirtualNetwork = $subnets.Vnics  |Export-Csv $csvVirtualNetworkpath -NoTypeInformation

    $csvSubnetspath = $Directory.FullName + "\" + $vnetwork.Name + "-Subnets.csv"
    $csvSubnets = $subnets |Select SubnetName,Addressprefix,NetWorkSecuritygroup,RouteTable |Export-Csv $csvSubnetspath -NoTypeInformation

}

#-----------------------------------------------------------
#         Virutal Machines
#-----------------------------------------------------------

$virtualmachines = get-azurermvm

$azurevms = foreach ($virtualmachine in $virtualmachines)
            {
                $vnics = Get-AzureRmNetworkInterface |Where {$_.Id -eq $VirtualMachine.NetworkProfile.NetworkInterfaces.Id}
                [pscustomobject]@{
                    Name = $virtualmachine.Name
                    ResourceGroup = $virtualmachine.ResourceGroupName
                    Size = $virtualmachine.HardwareProfile.VmSize
                    OSDisk = $virtualmachine.StorageProfile.OsDisk.Vhd.uri
                    DataDisk = $virtualmachine.StorageProfile.DataDisks.vhd.uri -join "**"
                    Vnic = $vnics.Name
                    VnicIP = $Vnics.IpConfigurations.PrivateIpAddress
                    Location = $virtualmachine.Location
                }
            }
#CSV Exports Virtual Machines
$csvVirtualMachinespath = $Directory.FullName + "\VirtualMachines.csv"
$csvVirtualNetwork = $azurevms  |Export-Csv $csvVirtualMachinespath -NoTypeInformation

#-----------------------------------------------------------
#         Network Security Groups
#-----------------------------------------------------------

$NWSecurityGroups = Get-AzureRmNetworkSecurityGroup
$AzureNWSecurityGroups = Foreach ($NWSecurityGroup in $NWSecurityGroups){

                            $defrules = $NWSecurityGroup.DefaultSecurityRules
                            $AzureSecGroupDefaultRules= foreach ($defrule in $defrules)
                                                        {
                                                            [pscustomobject]@{
                                                                NWSecurityGroupName=$NWSecurityGroup.Name
                                                                Name=$defrule.Name
                                                                Description=$defrule.Description
                                                                Protocol=$defrule.Protocol
                                                                SourcePortRange=$defrule.SourcePortRange
                                                                DestinationportRange=$defrule.DestinationportRange
                                                                SourceAddressPrefix=$defrule.SourceAddressPrefix
                                                                DestinationAddressPrefix=$defrule.DestinationAddressPrefix
                                                                Access=$defrule.Access
                                                                Priority=$defrule.Priority
                                                                Direction=$defrule.Direction
                                                            }
                                                        }

                            $cusrules = $NWSecurityGroup.SecurityRules
                            $AzureSecGroupCustomrules=foreach ($cusrule in $cusrules)
                                        {
                                            [pscustomobject]@{
                                                NWSecurityGroupName=$NWSecurityGroup.Name
                                                Name=$cusrule.Name
                                                Description=$cusrule.Description
                                                Protocol=$cusrule.Protocol
                                                SourcePortRange=$cusrule.SourcePortRange
                                                DestinationportRange=$cusrule.DestinationportRange
                                                SourceAddressPrefix=$cusrule.SourceAddressPrefix
                                                DestinationAddressPrefix=$cusrule.DestinationAddressPrefix
                                                Access=$cusrule.Access
                                                Priority=$cusrule.Priority
                                                Direction=$cusrule.Direction
                                            }
                                        }
                            $NSGSubnets = $NWSecurityGroup.Subnets
                            $AzureSecGroupSubnets = foreach ($NSGSubnet in $NSGSubnets)
                            {
                                $Ssss = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnetwork |where {$_.Id -eq $NSGSubnet.Id}
                                    [pscustomobject]@{
                                        NWSecurityGroupName=$NWSecurityGroup.Name
                                        NWSecurityResourceGroupName =$NWSecurityGroup.ResourceGroupName
                                        Name=$Ssss.Name
                                        Type = "Subnet"
                                        IPAddresses = $Ssss.AddressPrefix 

                                        }
                            }
                            $NSGNics = $NWSecurityGroup.NetWorkInterfaces
                            $AzureSecGroupNics = foreach ($NSGNic in $NSGNics)
                            {
                                $nnnn = Get-AzureRmNetworkInterface |Where  {$_.Id -eq $NSGNic.id}
                                    [pscustomobject]@{
                                        NWSecurityGroupName=$NWSecurityGroup.Name
                                        NWSecurityResourceGroupName =$NWSecurityGroup.ResourceGroupName
                                        Name=$nnnn.Name
                                        Type = "Nic"
                                        IPAddresses = $nnnn.IpConfigurations.PrivateIpAddress
                                        }
                            }

$AllAzureSecGroupRules = $AzureSecGroupDefaultRules+ $AzureSecGroupCustomrules
$NSGOverview = $AzureSecGroupSubnets + $AzureSecGroupNics

[pscustomobject]@{
    NWSecurityGroupName=$NWSecurityGroup.Name
    NWSecurityGroupResourceGroupName=$NWSecurityGroup.ResourceGroupName
    NWSecurityGroupRules = $AllAzureSecGroupRules
    NWSecurityGroupSubnets = $AzureSecGroupSubnets
}

#CSV Exports
$csvNSGRulesPath = $Directory.FullName + "\"+ $NWSecurityGroup.Name + "-Rules.csv"
$csvNSGRules = $AllAzureSecGroupRules |Sort Priority |Export-Csv $csvNSGRulesPath -NoTypeInformation

$csvNSGOverviewPath = $Directory.FullName + "\"+ $NWSecurityGroup.Name + "-Overview.csv"
$csvNSGOverviews = $NSGOverview |Export-Csv $csvNSGOverviewPath -NoTypeInformation

}

#-----------------------------------------------------------
#         Storage Accounts
#-----------------------------------------------------------

$StorageAccounts = Get-AzureRmStorageAccount

$blobs = foreach ($StorageAccount in $StorageAccounts)
{
$SourceContext = $StorageAccount.
$containers = Get-AzureStorageContainer -Context  $StorageAccount.Context.StorageAccount

foreach ($container in $containers)
{
    $conblobs = Get-AzureStorageBlob -Container $container.Name -Context $StorageAccount.Context.StorageAccount
    foreach ($conblob in $conblobs)
    {
        [int]$BlobSize = $conblob.Length / 1024 / 1024 / 1024
        [pscustomobject]@{
            SANAme = $StorageAccount.StorageAccountName
            SAType = $StorageAccount.AccountType
            SABlobEndpoint = $StorageAccount.Context.BlobEndPoint
            SATableEndPoint = $StorageAccount.Context.TableEndPoint
            SAQueueEndpoint = $StorageAccount.Context.QueueEndPoint
            SAContainerName = $container.Name
            BlobName=$conblob.Name
            BlobSize =$BlobSize
            BlobType = $conblob.BlobType
            Bloburi = $StorageAccount.Context.BlobEndPoint + $container.Name + $conblob.Name

        }
    }
}


}

#CSV Exports
$csvSAPath = $Directory.FullName + "\StorageOverview.csv"
$csvSA = $blobs |Export-Csv $csvSAPath -NoTypeInformation


ConvertCSV-ToExcel -inputfile @($csvrgGroupspath,$csvVirtualNetworkpath,$csvSubnetspath,$csvVirtualMachinespath,$csvNSGRulesPath,$csvNSGOverviewPath,$csvSAPath) -output 'AzureInventory.xlsx'
```