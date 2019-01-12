#Created by Joe B. 
#02-19-16 16:12 
  
#Updated by Joe B. 
#02-25-16 13:53 
  
#Get appname 
$appname = Read-Host -Prompt 'Input a unique string for the app' 
#param ([string]$appname) 
  
$vCenter = Read-Host -Prompt 'Input your vCenter server FQDN' 
  
# Connect to vCenter via PowerCLI 
Connect-VIServer $vCenter 
  
#Make sure the user passed a variable and is connected to a vCenter server 
if ($appname -eq ""){Write-Host -ForegroundColor Red "You must provide unique app string! ex: Cati_02-16-16";break} 
if ($global:DefaultVIServer.ProductLine -ne "vpx"){Write-Host -ForegroundColor Red "You must be connected to vCenter VCSA02 to run this script!";break} 
  
#Set the datastore to VDI-Apps-DS01 
$datastore = Get-Datastore VDI-Apps-DS01 
  
#Create the ds location 
New-PSDrive -Location $datastore -Name ds -PSProvider VimDatastore -Root '\' 
  
#Copy the file from Pod A to Pod B 
copy ds:\cloudvolumes\apps\$appname* ds:\cloudvolumesPodB\apps\ -Confirm 
  
#Tell the user they are not done 
Write-Host -ForegroundColor Green "**********************************" 
Write-Host -ForegroundColor Green "You must now go to the Pod B manager and import the AppStack." 
Write-Host -ForegroundColor Green "**********************************" 
  
# Disconnect from vCenter 
Disconnect-VIserver -Confirm:$false 
