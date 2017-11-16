# Check Azure resource provider API version

```powershell
$Provider=Get-AzureRmResourceProvider|Out-GridView -PassThru
$Provider.ResourceTypes
```