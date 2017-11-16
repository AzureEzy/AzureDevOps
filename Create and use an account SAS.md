# PowerShell code snippets to use Shared access signatures

Follows the examples listed [here](https://docs.microsoft.com/en-us/azure/storage/common/storage-dotnet-shared-access-signature-part-1#sas-examples)

## Example: Create and use an account SAS

### Create Account SAS

Below is how the storage account is structured.

```powershell
# azureprep (resource group)
#   \-azprepstore (storage account)
#       \-testblobcontainer1 (blob container)
#           \- docker.png (blob)

```

First, step is to create the Account SAS token using AzureRM and AzureSM PowerShell modules.

```powershell
# variables
$resourceGroupName = 'azureprep'
$StorageAccountName = 'azprepstore'
# Login to ASM & ARM modules, the cmdlets for creating SAS tokens are not yet available under ARM modules
Add-AzureAccount
Login-AzureRmAccount

# Get all azure subscription which are attached with your account
Get-AzureSubscription | Sort-Object -Property SubscriptionName | Select-Object -Property SubscriptionName

# Select a subscription where action need to perform
Select-AzureSubscription –SubscriptionName "Visual Studio Dev Essentials"

# Discover the Azure.Storage module to list out cmdlets which have the verb New
Get-Command -Verb New -Module Azure.Storage


# get Storage Key
$storKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName).Value[0]

# create the main Storage account Context
$storCont = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storKey

# Create an account SAS token - valid for Blob & File services.
# Gives client permission to read, write, and list permissions to access service-level APIs.
$storSAS = New-AzureStorageAccountSASToken -Service Blob,File -ResourceType Service `
    -Permission "rwl" -Protocol HttpsOnly -Context $storCont

# Display the SAS token generated
$storSAS
```


### Use Account SAS (created above)

Open another PowerShell console, this will act as a client. The intent here is to show that using SAS token one can access the storage resource independently from another client.

```powershell
# variables
$StorageAccountName = 'azprepstore'
$storSAS = '<SAS token value generated in previous step>'

# Create the new storage context with the Account SAS token generated above.
$ClientContext = New-AzureStorageContext -SasToken $storSAS -StorageAccountName $StorageAccountName

# try to fetch the Blobs using the above context and it will fail
# since the SAS token only grants access to the Service level APIs

Get-AzureStorageBlob -Container testblobcontainer1 -Context $ClientContext

# now try to fetch the Blob service properties (logging and metrics)
Get-AzureStorageServiceMetricsProperty -ServiceType Blob -MetricsType Hour -Context $ClientContext
Get-AzureStorageServiceLoggingProperty -ServiceType Blob -Context $ClientContext 

# In order to set the service properties follow through
# create the storage credentials from the Account SAS token
$storCreds = [Microsoft.WindowsAzure.Storage.Auth.StorageCredentials]::new($storSAS)

# create cloud storage account object
$cloudStorageAccount = [Microsoft.WindowsAzure.Storage.CloudStorageAccount]::new($storCreds, $StorageAccountName, $null, $true)

# create a BlobClient from the above cloud storage account object
$BlobClient = $cloudStorageAccount.CreateCloudBlobClient()

# retrieve the service properties (logging and metrics)
$BlobClient.GetServiceProperties()

# set the service properties
# In the sample below, we will modify the logging retention days for the Blob service
# first create copy of the existing service properties
$copyofServiceProperties = $BlobClient.GetServiceProperties()

# Now modify the retention days in the copied object 
$copyofServiceProperties.Logging.RetentionDays = 14

# Now use this modified copy of the service properties with the SetServiceProperties() method on BlobClient
$BlobClient.SetServiceProperties($copyofServiceProperties)

# Wait for few seconds for these changes to be reflected
Start-Sleep -seconds 4

# Now fetch the updated service properties from the BlobClient object
# You must notice that the retention days have been modified
$BlobClient.GetServiceProperties()
```