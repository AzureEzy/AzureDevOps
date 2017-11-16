# Steps to increase the data disk size

Please take a note to **Backup data before you perform below actions**

Define variables with the VM name and the cloud service name (classic ASM).

```powershell
$vmname="vpn000"
$servicename="vpn000"
```

## 1. Get data disk name

```powershell
#OS disk
Get-AzureVM -ServiceName $servicename -Name $vmname | Get-azureosDisk
#Data disk

Get-AzureVM -ServiceName $servicename -Name $vmname | Get-azuredataDisk
```

Output of the above cmdlet is used to get the data disk name. See below:

```Output
HostCaching         : None
DiskLabel           : ResizeDisk
DiskName            : vpn000-vpn000-0-201512100417240077 <------------------Get Disk Name
Lun                 : 0
LogicalDiskSizeInGB : 50
MediaLink           :https://portalvhdskpqv2xx70nrh6.blob.core.windows.net/vhds/vpn000-vpn000-1210-1.vhd
SourceMediaLink     :
IOType              : Standard
ExtensionData       :
```

Gather the disk name from the above output and store it in a variable along with the new size required.

```powershell
$diskname= Get-AzureVM -ServiceName $servicename -Name $vmname | Get-azuredataDisk | Select-Object -ExpandProperty DiskName
$newsize="50"
```

## 2. Stop deallocate the VM

```powershell
#OS disk
#we have to shut down VM in the portal
Get-AzureVM  -ServiceName $servicename -Name $vmname  | Stop-AzureVM -Force
```

## 3. Expand the disk size

```powershell
Update-AzureDisk -Label ResizeDisk -DiskName $diskname  -ResizedSizeInGB $newsize
```

## 4. Start Azure VM

```powershell
Get-AzureVM -ServiceName $servicename  -Name $vmname| Start-AzureVM
```

## 5. Extend disk in OS

* For Windows VM
  * RDP TO VM
  * Open Disk Management
  * Right Click the Drive
  * Select EXTEND option
  * EXTEND to target Size of 50 GB

* For Linux VM
  * Once the PowerShell commands complete, cleanly restart the VM.
  * SSH into the VM and check the data disk device has increased.

  ```shell
  Bash# dmesg |grep -i sdc
  [sdc] 1048576000 512-byte logical blocks: (536 GB/500 GiB)
  ```

  * Run sudo fdisk /dev/sdc
    * use p to list the partitions. Make note of the start cylinder of /dev/sdc1
    * use d to delete first the swap partition (2) and then the /dev/sdc1 partition. This is very scary but is actually harmless as the data is not written to the disk until you write the changes to the disk.
    * use n to create a new primary partition. Make sure its start cylinder is exactly the same as the old /dev/sdc1 used to have. For the end cylinder agree with the default choice, which is to make the partition to span the whole disk.
    (use a to toggle the bootable flag on any bootable device)
    * review your changes, make a deep breath and use w to write the new partition table to disk. You'll get a message telling that the kernel couldn't re-read the partition table because the device is busy, but that's ok.
  * Reboot with sudo reboot. When the system boots, you'll have a smaller filesystem living inside a larger partition.
  * Run sudo resize2fs /dev/sdc1 - this form will default to making the filesystem to take all available space on the partition.
