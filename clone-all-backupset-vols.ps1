$dev = Get-AzureStorSimpleDevice
$targetacr = Get-AzureStorSimpleAccessControlRecord -ACRName “<<_DESIRED_ACR_>>”

$lvmbackup = Get-AzureStorSimpleDeviceBackupPolicy -DeviceName $dev -BackupPolicyName “<<_BACKUP_POLICY_NAME_>>” | Get-AzureStorSimpleBackup -DeviceName $dev -First 1
$lvmbackupvolsnaps = $lvmbackup.Snapshots

$i=1
foreach ($snaptoclone in $lvmbackupvolsnaps) 
{ 
    Start-AzureStorSimpleBackupCloneJob -SourceDeviceName $dev -TargetDeviceName $dev -BackupId $lvmbackup.InstanceId -Snapshot $snaptoclone -CloneVolumeName “CLONE—LVM-Disk$i” -TargetAccessControlRecords $targetacr -force 
    $i++ 
}