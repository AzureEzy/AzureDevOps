# Get the VHD count per storage account

```powershell
$storageAccounts = Get-AzureRmStorageAccount
$output = New-Object psobject
$output | Add-Member -MemberType NoteProperty -Name "Storage Account" -Value "NOT SET"
$output | Add-Member -MemberType NoteProperty -Name "Storage Type" -Value "NOT SET"
$output | Add-Member -MemberType NoteProperty -Name "VHDs Count" -Value "NOT SET"

foreach($storageAccount in $storageAccounts){
    $count = 0
    $sa = Get-AzureRmStorageAccount -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName
    $containers = Get-AzureStorageContainer -Context $sa.Context
    foreach($container in $containers){
        $blobs = Get-AzureStorageBlob -Context $sa.Context -Container $container.Name
        foreach($blob in $blobs){
            if($blob.BlobType -eq [Microsoft.WindowsAzure.Storage.Blob.BlobType]::PageBlob -and $blob.Name -match ".vhd"){
                $count += 1
            }
        }
    }
    $output.'VHDs Count' = $count
    $output.'Storage Type' = $storageAccount.Sku.Name
    $output.'Storage Account' = $storageAccount.StorageAccountName
    Export-Csv -InputObject $output -Path "D:\Stoageoverview.csv" -encoding ASCII -Append -NoTypeInformation
}
```