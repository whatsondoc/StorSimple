$devices = Get-SSDevice
$vols = @()
$backupdisk = @()
$snap = @()

$targetAcr = Get-SSAccessControlRecord -ACRName Wildcard

if ($targetAcr -eq $null) {
    echo “No target ACR found “
    return
}

foreach ($device in $devices)
{ 
    $VC = Get-SSDeviceVolumeContainer -DeviceName $device.FriendlyName; 
    if ($VC -eq $null) {
        echo “No VC found “
        return
    }
    foreach ($volC in $vc) 
    {
        $vols += Get-SSDeviceVolume -DeviceName $device.FriendlyName -VolumeContainer $volc
    } 
}

if ($vols -eq $null) {
    echo “No volumes found “
    return
}

foreach ($volume in $vols)
{
    $snaps = @()
    $temp = Get-SSDeviceBackup -DeviceName $device.FriendlyName -VolumeId $volume.InstanceId -First 1
    if ($temp -ne $null) {
        $backupdisk += Get-SSDeviceBackup -DeviceName $device.FriendlyName -VolumeId $volume.InstanceId -First 1

        foreach ($snaps in $temp[0].Snapshots)
        {
            if ($snaps.VolumeId -eq $volume.InstanceId)
            {
                $snap += $snaps
            }
        }
    }
}

if ($backupdisk -eq $null) {
    echo “No backups found “
    return
}

if ($snap -eq $null) {
    echo “No snapshots found “
    return
}

$i=0

foreach ($backup in $backupdisk)
{
    $targetname = $snap[$i].Name +”_ScriptClone”
    echo $backup.InstanceId $snap[$i].Name $targetname $targetAcr.Name + ” “
    Start-SSBackupCloneJob -BackupId $backup.InstanceId -Snapshot $snap[$i] -CloneVolumeName $targetname -TargetAccessControlRecords $targetAcr -Force
    $i++
}
