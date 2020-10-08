# Install IIS and configure IIS Websites with custom information using DSC.

Followiing DSC Configuration installs IIS on machine and also configure websites with custom information.

```PowerShell
Configuration Configure-Website
{
  param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$MachineName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$WebSitePrefix,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$DevPublicDNS,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$UatPublicDNS,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$ProdPublicDNS



  )
  
  Node $MachineName
  {  
            LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }


         #Install the IIS Role
          WindowsFeature IIS
         {
          Ensure = “Present”
          Name = “Web-Server”
         }

         #Install ASP.NET 4.5
         WindowsFeature ASP
         {
          Ensure = “Present”
          Name = “Web-Asp-Net45”
         }

         WindowsFeature WebServerManagementConsole
         {
          Name = "Web-Mgmt-Console"
          Ensure = "Present"
         }
         File devfolder
         {
            Type = 'Directory'
            DestinationPath = 'C:\inetpub\wwwroot\dev'
            Ensure = "Present"
            DependsOn       = '[WindowsFeature]ASP'
         }
         File uatfolder
         {
            Type = 'Directory'
            DestinationPath = 'C:\inetpub\wwwroot\uat'
            Ensure = "Present"
            DependsOn       = '[WindowsFeature]ASP'
         }  
         File prodfolder
         {
            Type = 'Directory'
            DestinationPath = 'C:\inetpub\wwwroot\prod'
            Ensure = "Present"
            DependsOn       = '[WindowsFeature]ASP'
         }
         
          xWebsite DevWebsite
         {
            Ensure          = 'Present'
            Name            = $WebSitePrefix + '-dev'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot\dev'
            BindingInfo     = @( MSFT_xWebBindingInformation
                                 {
                                   Protocol              = "HTTP"
                                   Port                  = 80
                                   HostName = $DevPublicDNS
                                 }
                                 
                                )
            DependsOn       = '[File]devfolder'
            
         } 
         xWebsite UatWebsite
         {
            Ensure          = 'Present'
            Name            = $WebSitePrefix +'-uat'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot\uat'
            BindingInfo     = @( MSFT_xWebBindingInformation
                                 {
                                   Protocol              = "HTTP"
                                   Port                  = 80
                                   HostName = $UatPublicDNS
                                 }
                                 
                                )
            DependsOn       = '[File]uatfolder'
         }

         xWebsite prodWebsite
         {
            Ensure          = 'Present'
            Name            = $WebSitePrefix +'-prod'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot\prod'
            BindingInfo     = @( MSFT_xWebBindingInformation
                                 {
                                   Protocol              = "HTTP"
                                   Port                  = 80
                                   HostName = $ProdPublicDNS
                                 }
                                 
                                )
            DependsOn       = '[File]prodfolder'
         }
    
  }
} 

```

To call this DSC Configuration save the PowerShell code above as ps1 file and zip the ps1 file, you may refer the below json snippet and Home page to know more how to use DSC extention in ARM templates.

```json
{
      "type": "Microsoft.Compute/virtualMachines/extensions",
      "name": "[concat(parameters('virtualMachineName'),'/', 'MyDSCConfig')]",
      "apiVersion": "2015-06-15",
      "location": "[resourceGroup().location]",
      "dependsOn": [
        "[concat('Microsoft.Compute/virtualMachines/', parameters('virtualMachineName'))]"
      ],
      "properties": {
        "publisher": "Microsoft.Powershell",
        "type": "DSC",
        "typeHandlerVersion": "2.19",
        "autoUpgradeMinorVersion": true,
        "settings": {
          "ModulesUrl": "https://YourConfigZipfileURL/Configure-SomeDSC.zip",
          "ConfigurationFunction": "Configure-SomeDSC.ps1\\Configure-SomeDSC",
          "Properties": {
            "MachineName": "[parameters('virtualMachineName')]",
            "WebSitePrefix":"WebsitePrefix",
            "DevPublicDNS":"DevPublicDNS",
            "UatPublicDNS":"UatPublicDNS",
            "ProdPublicDNS":"ProdPublicDNS"
          }
        },
        "protectedSettings": {
                      "configurationUrlSasToken": "[parameters('_artifactsLocationSasToken')]"
                  }
      }
}

```