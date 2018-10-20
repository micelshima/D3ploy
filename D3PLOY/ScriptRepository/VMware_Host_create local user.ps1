$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
if (![bool]$strusername) {$strusername = show-inputbox -message "username?"}
if (![bool]$strpassword) {$strpassword = show-inputbox -message "password?"}
if (![bool]$strdescription) {$strdescription = show-inputbox -message "description?"}
try {
	Add-PSSnapin VMware.VimAutomation.Core -ea SilentlyContinue # add VMware PS snapin
	if (!$?) {import-module "VMware.VimAutomation.Core" -ea stop} #cargo el modulo de powercli 6.5

	$logfile = "results\$($scriptbasename).csv"
	if (!(test-path $logfile)) {out-file $logfile -input "DeployInput	VMHost	VM	StartOrder	StartAction	StartDelay"}
	Set-PowerCLIConfiguration -DefaultVIServerMode Single -Scope 'Session' -InvalidCertificateAction 'Ignore' -Confirm:$false
	$HostServer = Connect-VIserver -server $computername -credential $creds

	New-VMHostAccount -Id $strusername -Password $strpassword -Description $strdescription -UserAccount
	
	}
	Disconnect-VIServer -server $computername -Confirm:$False

}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error' -logfile 'ps1command.log'}
