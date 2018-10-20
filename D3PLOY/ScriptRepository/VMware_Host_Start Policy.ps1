$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
try {
	Add-PSSnapin VMware.VimAutomation.Core -ea SilentlyContinue # add VMware PS snapin
	if (!$?) {import-module "VMware.VimAutomation.Core" -ea stop} #cargo el modulo de powercli 6.5

	$logfile = "results\$($scriptbasename).csv"
	if (!(test-path $logfile)) {out-file $logfile -input "DeployInput	VMHost	VM	StartOrder	StartAction	StartDelay"}
	Set-PowerCLIConfiguration -DefaultVIServerMode Single -Scope 'Session' -InvalidCertificateAction 'Ignore' -Confirm:$false
	$HostServer = Connect-VIserver -server $computername -credential $creds

	$VMhost = Get-VMHost|select extensiondata
	#$hostStartPolicy=Get-VMHostStartPolicy
	$VMStartPolicy=Get-VMstartpolicy
	$VMStartPolicy|%{
	$msg = '{0}	{1}	{2}	{3}	{4}	{5}' -f $computername, $VMhost.extensiondata.name, $_.VM, $_.StartOrder, $_.StartAction, $_.StartDelay
	out-file $logfile -input $msg -append
	}
	Disconnect-VIServer -server $computername -Confirm:$False
	if ($uihash.objcomputers.count -eq 0) {if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){start-process $logfile}}
}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error' -logfile 'ps1command.log'}
