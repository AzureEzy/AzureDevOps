# Take snapshot of the VM

 ```powershell

# Define the storage account and context.
$StorageAccountName = "*******************"
$StorageAccountKey = "**********************************************"
$Ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
# Define the variables.
$SrcContainerName = "******"
$DestContainerName = "*********"
$SrcBlobName = "**************.vhd"
$DestBlobName = "*******************"
$blob = Get-AzureStorageBlob -Context $Ctx -Container $SrcContainerName -Blob $SrcBlobName
$snap = $blob.ICloudBlob.CreateSnapshot()
Start-AzureStorageBlobCopy –Context $Ctx -ICloudBlob $snap -DestBlob $DestBlobName -DestContainer $DestContainerName

```