# PowerCLI-Extend-Disks.ps1 
# Must be run in VMware PowerCLI 
# Written by Jason Pearce, www.jasonpearce.com, (2015 June) 
# Inspiration from Brian Wuchner, Adam Stahl, and of course Luc Dekens (LucD) 
# Modified slightly by KJR 02-23-16 
# Added prompts for values 
  
# BEGIN Variables 
  
# vCenter that contains target VMs 
$vCenter = Read-Host -Prompt 'Input your vCenter server FQDN' 
$Cluster = Read-Host -Prompt 'Input the cluster name where VMs are located' 
$VMName = Read-Host -Prompt 'Input VM Name. Asterisk wildcard is acceptable. CAREFUL! Must match on both Windows and VM Names' 
$WindowsVolumeLetter = Read-Host -Prompt 'Input Windows drive letter. e.g. C' 
$VMwareDriveNumber = Read-Host -Prompt 'Input Hard Disk #' 
  
# New hard drive size you want (should be larger than current drive size) 
#$NewCapacityGB=60 
$NewCapacityGB = Read-Host -Prompt 'Input new size of disk in GB' 
$NewCapacityKB = [Decimal]$NewCapacityGB * 1024 * 1024 
$NewCapacityKB = [Int64]$NewCapacityKB 
  
# Connect to vCenter via PowerCLI 
Connect-VIServer $vCenter 
  
# One or more virtual machines you want to target (modify and uncomment this line) 
$VMs=(Get-Cluster -Name $Cluster | Get-VM -Name $VMName) 
# $VMs=("VM1","VM2","VM3") 
  
# Virtual Machine Windows Credentials (a local admin account) 
$GuestUser = Read-Host 'Please enter Windows administrator username' 
$GuestPassword = Read-Host -assecurestring 'Please enter Windows administrator password' 
  
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist ($GuestUser,$GuestPassword) 
  
# END Variables 
  
# BEGIN Script 
  
Write-Host "Performing Operation on the below VMs:" 
$VMs | FT Name 
$ModifiedVMs = @() 
  
# BEGIN foreach loop 
foreach ($VM in $VMs) { 
  
# Have vSphere PowerCLI increase the size of the first hard drive in each target  
try{ 
    Get-VM $VM | Get-HardDisk | Where-Object {$_.Name -eq "Hard Disk $VMwareDriveNumber"} | Set-HardDisk -CapacityKB $NewCapacityKB -Confirm:$false 
    } 
catch{ 
    Write-Host $Error[0].Exception 
    } 
} 
  
#Needed to expand the $WindowsVolumeLetter variable 
$ScriptBlock1String = "Start-Process -FilePath 'C:\Windows\system32\cmd.exe' -ArgumentList ('/c','ECHO RESCAN > C:\Scripts\DiskPart.txt && ECHO SELECT Volume $WindowsVolumeLetter >> C:\Scripts\DiskPart.txt && ECHO EXTEND >> C:\Scripts\DiskPart.txt && ECHO EXIT >> C:\Scripts\DiskPart.txt && timeout 5') -NoNewWindow" 
$ScriptBlock1 = [scriptblock]::Create($ScriptBlock1String) 
$ScriptBlock2 = {Start-Process -FilePath "C:\Windows\system32\DiskPart.exe" -ArgumentList ("/s","C:\Scripts\DiskPart.txt") -Wait -Verb RunAs} 
$ScriptBlock3 = {Start-Process -FilePath "C:\Windows\system32\cmd.exe" -ArgumentList ("/c","DEL C:\Scripts\DiskPart.txt /Q") -NoNewWindow} 
  
$Computers = Get-ADComputer -Filter 'Name -like $VMName' 
  
foreach ($Computer in $Computers){ 
# Run DISKPART in the guest OS of each of the specified virtual machines 
try{ 
    #Invoke-VMScript was unreliable 
    Write-Host $Computer.Name 
    Invoke-Command -ComputerName $Computer.Name -ScriptBlock $ScriptBlock1 
    Invoke-Command -ComputerName $Computer.Name -ScriptBlock $ScriptBlock2 -Credential $cred 
    Invoke-Command -ComputerName $Computer.Name -ScriptBlock $ScriptBlock3 
    } 
catch{ 
    Write-Host $Error[0].Exception 
    } 
} 
# END foreach loop 
  
# Disconnect from vCenter 
Disconnect-VIserver -Confirm:$false 
  
# END Script
