$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)) {out-file $logfile -input "COMPUTERNAME	TOOLS VERSION	TOOLS STATUS"}
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
	$result=$vm| % { get-view $_.id } | select name, @{Name='ToolsVersion'; Expression={$_.config.tools.toolsversion}}, @{ Name='ToolStatus'; Expression={$_.Guest.ToolsVersionStatus}}
	out-file $logfile -input "$Computername	$($result.ToolsVersion)	$($result.ToolStatus)" -append
	if($result.ToolStatus -eq "guestToolsCurrent"){$color='OK'}
	else{$color='Warning'}
	out-textblock -ComputerName $computername -Source $scriptbasename -Message $result.ToolStatus -MessageType $color
	}
else {out-textblock -ComputerName $computername -Source $scriptbasename -Message "No encontrado" -MessageType 'Error' -logfile 'ps1command.log'}
Disconnect-VIServer $VCenter -Confirm:$False
if ($uihash.objcomputers.count -eq 0) {if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){start-process $logfile}}