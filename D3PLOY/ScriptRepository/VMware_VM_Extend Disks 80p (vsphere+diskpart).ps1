$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)) {out-file $logfile -input "COMPUTERNAME	NAME	DRIVE	SIZEGB	FREEGB	PERCENTUSED	INCREMENTGB80PERCENTUSED"}
try {
	Add-PSSnapin VMware.VimAutomation.Core -ea SilentlyContinue # add VMware PS snapin
	if (!$?) {import-module "VMware.VimAutomation.Core" -ea stop} #cargo el modulo de powercli 6.5
}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error' -logfile 'ps1command.log'}
$VCenter = "SERVERVCENTER.domain.local"
Set-PowerCLIConfiguration -DefaultVIServerMode Single -Scope 'Session' -InvalidCertificateAction 'Ignore' -Confirm:$false
if ($scope -eq '') {$params = @{'server' = $VCenter}
}
else {$params = @{'server' = $VCenter; 'credential' = $creds}
}
$VCServer = Connect-VIserver @params


if ($vm = get-vm -name $computername) {
	$vspheredisks = $vm|Get-HardDisk|select Name,capacityGB|select @{l='capacityGB';e={[math]::Round($_.capacityGB,0)}},name
	$guestdisks=$vm|Get-VMGuest|select -expand disks|select @{l='capacityGB';e={[math]::Round($_.capacityGB,0)}},FreeSpaceGB,Path
	$disks=@()
	foreach($guestdisk in $guestdisks)
	{
	$disk=""|select name,id,capacityGB,freeGB,percentused,increaseGB80percentused
	$disk.name=$vspheredisks|?{$_.capacityGB -eq $guestdisk.capacityGB}|select -expand Name
	$disk.id=($guestdisk.path -split(":"))[0]
	$disk.capacityGB=$guestdisk.capacityGB
	$disk.freeGB=$guestdisk.freespaceGB
	$disk.percentused=($guestdisk.capacityGB - $guestdisk.freespaceGB)/$guestdisk.capacityGB * 100
	$disk.increaseGB80percentused=[math]::Round(($guestdisk.capacityGB - 5 * $guestdisk.freespaceGB)/4,0)
	#log
	$line='{5}	{0}	{1}	{6:N1}GB	{2:N1}GB	{3:N0}%	{4}GB' -f $disk.name,$disk.id, $disk.freeGB, $disk.percentused, $disk.increaseGB80percentused,$computername,$disk.capacityGB
	out-file $logfile -input $line -append	
		if ($disk.increaseGB80percentused -gt 0 -and $disk.name.gettype() -match "String"){
		$disks+=$disk
		$msg='{0}={1}:\{2:N1}GB free({3:N0}% Used) {4}GB needed to compliance' -f $disk.name,$disk.id, $disk.freeGB, $disk.percentused, $disk.increaseGB80percentused
		out-textblock -ComputerName $computername -Source $scriptbasename -Message $msg -MessageType 'Warning'
		}
	}
	foreach($disk in $disks)
	{

		$NewCapacityGB = $disk.CapacityGB + $disk.increaseGB80percentused
		$vm|Get-HardDisk | Where-Object {$_.Name -eq $disk.name} | Set-HardDisk -CapacityGB $NewCapacityGB -Confirm:$false
		$batcommand = "ECHO RESCAN > C:\DiskPart.txt && ECHO SELECT Volume $($disk.id) >> C:\DiskPart.txt && ECHO EXTEND >> C:\DiskPart.txt && ECHO EXIT >> C:\DiskPart.txt && DiskPart.exe /s C:\DiskPart.txt && DEL C:\DiskPart.txt /Q"
		if ($scope = '') {
			$vm|Invoke-VMScript -ScriptText $batcommand -ScriptType BAT
		}
		else {
			$vm|Invoke-VMScript -ScriptText $batcommand -ScriptType BAT -Guestcredential $creds
		}
	if(!$?){out-textblock -ComputerName $computername -Source $scriptbasename -Message "No se pudo ejecutar diskpart" -MessageType 'Error' -logfile 'ps1command.log'}
	else{out-textblock -ComputerName $computername -Source $scriptbasename -Message "Extendido disco (diskpart)" -MessageType 'OK' -logfile 'ps1command.log'}
	}
}
else {out-textblock -ComputerName $computername -Source $scriptbasename -Message "No encontrado" -MessageType 'Error' -logfile 'ps1command.log'}
Disconnect-VIServer $VCenter -Confirm:$False