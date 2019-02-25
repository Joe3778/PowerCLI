#Connect to vCenter Server
#Example:
##getvmdiskmap.ps1 VMName WindowsFQDN

param ([string]$vmname, [string]$winname, [switch]$grid, [switch]$VIX, [switch]$noSSO)

if ($global:DefaultVIServer.ProductLine -ne "vpx"){Write-Host -ForegroundColor Red "You must be connected to vCenter to run this script!";break}

#version 1.2

if (!($vmdisks=(get-vm $vmname|get-view).Config.Hardware.Device|?{$_.Backing.Uuid}|%{$_|select @{n="VMlabel";e={$_.DeviceInfo.label}},@{n="VMFilename";e={$_.Backing.FileName}},@{n="UUID";e={($_.Backing.Uuid).replace("-","")}},@{n="VMSize";e={$_.CapacityInKB/1MB}}})){Write-Host -ForegroundColor Red "Not a valid VM!";break}

if ($VIX)
	{
	if ($noSSO)
		{
		$guestcredentials = Get-Credential -Credential $null
		if (!($vixdisks = get-vm $vmname|Invoke-VMScript "Get-WmiObject Win32_DiskDrive|select SerialNumber,DeviceID,Size" -ScriptType "PowerShell" -guestcredential $guestcredentials)){Write-Host -ForegroundColor Red "No VIX data!";return}
		}
	else
		{
		if (!($vixdisks = get-vm $vmname|Invoke-VMScript "Get-WmiObject Win32_DiskDrive|select SerialNumber,DeviceID,Size" -ScriptType "PowerShell" -guestcredential $null)){Write-Host -ForegroundColor Red "No VIX data!";return}
		}

	$vixdiskslist = $vixdisks.ScriptOutput.split(" ")|?{$_ -match "6000c|PHYSICALDRIVE"}|%{$_.Trim()}
	$windisks = @()

	foreach ($i in (0..($vixdiskslist).count))
		{
		if ($i%2 -eq 0)
			{
			$vixdisktab = "" | select SerialNumber,DeviceID,Size
			$vixdisktab.SerialNumber = $vixdiskslist[$i]
			}
		else
			{
			$vixdisktab.DeviceID = $vixdiskslist[$i]
			$windisks += $vixdisktab
			}
		}
	if (!$windisks){Write-Host -ForegroundColor Red "No VIX data!";return}
	}
else
	{
	if ($noSSO)
		{
		$guestcredentials = Get-Credential -Credential $null
		if (!($windisks=(Get-WmiObject Win32_DiskDrive -ComputerName $winname -Credential $guestcredentials|select SerialNumber,DeviceID,Size))){Write-Host -ForegroundColor Red "No WMI data!";return}
		}
	else
		{
		if (!($windisks=(Get-WmiObject Win32_DiskDrive -ComputerName $winname|select SerialNumber,DeviceID,Size))){Write-Host -ForegroundColor Red "No WMI data!";return}
		}
	}

$uuidmap=@()

foreach ($vmdisk in $vmdisks)
	{
	$windisk=$windisks|?{$_.SerialNumber -eq $vmdisk.UUID}
	if ($windisk)
		{
		$vmwinmap = "" | select WinID, VMID, Winsize, VMsize, VMPath
		
		$vmwinmap.WinID = $windisk.DeviceID
		$vmwinmap.VMID = $vmdisk.VMlabel
		$vmwinmap.Winsize = [Math]::Round($windisk.Size/1GB, 0)
		$vmwinmap.VMsize = $vmdisk.VMSize
		$vmwinmap.VMPath = $vmdisk.VMFilename
		
		$uuidmap += $vmwinmap
		}
	}

if ($grid)
	{$uuidmap|out-gridview -title $vmname}
else
	{$uuidmap|ft -autosize}