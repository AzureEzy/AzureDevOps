# Azure CLI short cuts
[Read more here](https://buildazure.com/2017/06/07/azure-cli-2-0-quickly-start-stop-all-vms/)

## VM management operations

### Delete RG

```shell
az group delete --resource-group <rg_name> -yes
```

### Stop a vm in a RG

```shell
az vm stop --name <vm_name> --resource-group <rg_name>
```

### start a vm in a RG

```shell
az vm start --name <vm_name> --resource-group <rg_name>
```

### Deallocate a VM with Azure CLI

```shell
az vm deallocate --name <vm_name> --resource-group <rg_name>
```

### Start, Stop, Deallocate VMs by ID

```shell
az vm start --ids <vm_ids>
az vm stop --ids <vm_ids>
az vm deallocate --ids <vm_ids>
```

Example

```azcli
az start --ids "/subscriptions/a35d316a-2a2a-48e2-8834-55481f7bbb48/resourceGroups/WIN16VM/providers/Microsoft.Compute/virtualMachines/Win16VM"
```

### Get list of VM Ids

For the above VM operations it is helpful to gather the IDs of the VMs.
The below command will output the Ids of all VMs in my Subscription.

```shell
az vm list --query "[].id" -o tsv
```

For gathering the list of VM ids in a RG.

```shell
az vm list --query "[].id" -o tsv --resource-group <rg_name>
```

### Start, Stop & Deallocate multiple VMs at once.

All the above concepts can be rolled into a single one.

```shell
az vm start --ids $(
    az vm list --query "[].id" -o tsv | grep "test"
)
```

### Find the current private IP of the VM

```shell
az vm show -g <rg_name> -n <vm_name> --show-details  --query "privateIps" 
```

### Set the private IP of the VM

This step is used while creating the VM, once the nic is created it is passed as a argument to the --nics parameter of the az vm create command.

```shell
az network nic create \
--resource-group <rg_name> \
--name <nic_name> \
--location southeastasia \
--subnet FrontEnd \
--private-ip-address 192.168.1.101 \
--vnet-name TestVNet
```