$dev = <<_SS_device_name_>>
### Or, bring all StorSimple devices into scope:
# $dev = Get-AzureStorSimpleDevice

$vcs = Get-SSDeviceVolumeContainer -DeviceName $dev

$vcnames = $vcs.Name

$allvols = foreach ($vc in $vcnames) 
{ 
    Get-SSDeviceVolumeContainer -DeviceName $dev -VolumeContainerName $vc | Get-SSDeviceVolume -DeviceName $dev 
}

write-output "All volume names:"
$allvols.Name

write-output "All online volumes:"
$allvols | where {$_.Online -eq $true}


### Deleting cloned volumes starting with 'CLONE':

# $clonevols = $allvols.Name | where {$_ -match “CLONE”}
# $clonevolnames = $clonevols.Name
# foreach ($offlineclonevol in $clonevolnames) 
# { 
#   set-ssdevicevolume -DeviceName $dev -VolumeName $offlineclonevol -Online $false 
# }
# foreach ($deleteclonevol in $clonevolnames) 
# { 
#   remove-ssdevicevolume -devicename $dev -volumename $deleteclonevol 
# }