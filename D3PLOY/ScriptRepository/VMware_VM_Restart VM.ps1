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
	$vm|Restart-VMGuest -Confirm:$False
}
else {out-textblock -ComputerName $computername -Source $scriptbasename -Message "No encontrado" -MessageType 'Error' -logfile 'ps1command.log'}
Disconnect-VIServer $VCenter -Confirm:$False