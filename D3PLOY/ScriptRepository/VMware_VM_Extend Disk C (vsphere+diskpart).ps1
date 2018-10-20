$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
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
	$currentCapacityGB = $vm|Get-HardDisk | Where-Object {$_.Name -eq "Hard Disk 1"}|select -expand capacityGB
	if (![bool]$increaseGB) {$increaseGB = show-inputbox -message "Cuantos GB quieres ampliar en el disco C?"}
	$NewCapacityGB = $currentCapacityGB + $increaseGB
	$vm|Get-HardDisk | Where-Object {$_.Name -eq "Hard Disk 1"} | Set-HardDisk -CapacityGB $NewCapacityGB -Confirm:$false
	$batcommand = "ECHO RESCAN > C:\DiskPart.txt && ECHO SELECT Volume C >> C:\DiskPart.txt && ECHO EXTEND >> C:\DiskPart.txt && ECHO EXIT >> C:\DiskPart.txt && DiskPart.exe /s C:\DiskPart.txt && DEL C:\DiskPart.txt /Q"
	if ($scope = '') {
		$vm|Invoke-VMScript -ScriptText $batcommand -ScriptType BAT
	}
	else {
		$vm|Invoke-VMScript -ScriptText $batcommand -ScriptType BAT -Guestcredential $creds
	}

}
else {out-textblock -ComputerName $computername -Source $scriptbasename -Message "No encontrado" -MessageType 'Error' -logfile 'ps1command.log'}
Disconnect-VIServer $VCenter -Confirm:$False