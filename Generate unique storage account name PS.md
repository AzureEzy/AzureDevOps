# Automate the generation of a unique storage account name

Credits- [Opsgility post](https://www.opsgility.com/blog/2016/05/09/automate-finding-a-unique-azure-storage-account-name-arm) by Steve Ross

Define variables to begin with.

```powershell
# Storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only.
$saPrefix = "azprep"
$rgName = "azureprep"
$location = "South India"
$saType = "Standard_LRS"
```

Login and set the AzureRM context.

```powershell
# Login to Resource Manager framework
Login-AzureRmAccount
# Load your subscriptions
Get-AzureRmSubscription
# Select the correct subscription to work with
Set-AzureRmContext -SubscriptionId <Your Subscription ID Here>

```

Let's use the built-in **Get-Random** cmdlet to generate a temp storage account name.

```powershell
$randomnumber = Get-Random -Minimum 0 -Maximum 9999
$tempName = $saPrefix + $randomnumber
```

Now using the above generated temp storage account name, let's check if the storage name is available or not.If not we will loop until we find an available account name

```powershell
# Test the account name availability
$var1 = Get-AzureRmStorageAccountNameAvailability -Name $tempName
# Check if the name is available
If ($var1.NameAvailable -ne $True) {
    # if the name is not available keep looping until it is available
    Do {
        $randomnumber = Get-Random -Minimum 0 -Maximum 9999
        $tempName = $saPrefix + $randomnumber
        $var1 = Get-AzureRmStorageAccountNameAvailability -Name $tempName
    }
    Until ($var1.NameAvailable -eq $True)
}
# assign and use the temporary storage account name now.
$saName = $tempName
# provision the Azure storage account now
New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName -Type $saType -Location $location

```