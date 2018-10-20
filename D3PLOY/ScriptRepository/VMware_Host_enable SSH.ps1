$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
try {
	Add-PSSnapin VMware.VimAutomation.Core -ea SilentlyContinue # add VMware PS snapin
	if (!$?) {import-module "VMware.VimAutomation.Core" -ea stop} #cargo el modulo de powercli 6.5

	Set-PowerCLIConfiguration -DefaultVIServerMode Single -Scope 'Session' -InvalidCertificateAction 'Ignore' -Confirm:$false
	$HostServer = Connect-VIserver -server $computername -credential $creds

	$result = Start-VMHostService -HostService (get-VMhost|Get-VMHostService|? { $_.Key -eq "TSM-SSH"}) -confirm:$false
	$msg = '{0}: {1} now is {2}' -f $computername, $result.label, $result.running
	out-textblock -ComputerName $computername -Source $scriptbasename -Message $msg -logfile 'ps1command.log'

	Disconnect-VIServer -server $computername -Confirm:$False
}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error' -logfile 'ps1command.log'}
