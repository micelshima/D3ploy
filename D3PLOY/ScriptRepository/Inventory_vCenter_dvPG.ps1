$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)) {out-file $logfile -input "COMPUTERNAME	PORTGROUP	VLAN	VDSWITCH"}
try {
	import-module "VMware.VimAutomation.Core" -ea stop #cargo el modulo de powercli 6.5
	import-module "VMware.VimAutomation.Vds" -ea stop #cargo el modulo de powercli 6.5

	$VCenter = "SERVERVCENTER.domain.local"
	Set-PowerCLIConfiguration -DefaultVIServerMode Single -Scope 'Session' -InvalidCertificateAction 'Ignore' -Confirm:$false
	if ($scope -eq '') {$params = @{'server' = $VCenter}
	}
	else {$params = @{'server' = $VCenter; 'credential' = $creds}
	}
	$VCServer = Connect-VIserver @params

	if ($vm = get-vm -name $computername|get-view) {
		$portgroup = Get-VDPortgroup -id $vm.network|select vlanconfiguration, name, VDSwitch
		out-file $logfile -input "$Computername	$($portgroup.name)	$($portgroup.vlanconfiguration)	$($portgroup.VDSwitch)" -append

		out-textblock -ComputerName $computername -Source $scriptbasename -Message $portgroup.name -MessageType 'Info'
	}
	else {out-textblock -ComputerName $computername -Source $scriptbasename -Message "No encontrado" -MessageType 'Error' -logfile 'ps1command.log'}
	Disconnect-VIServer $VCenter -Confirm:$False
	if ($uihash.objcomputers.count -eq 0) {if ([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?", $uihash.tag, 'YesNoCancel', 'Question') -eq 'Yes') {start-process $logfile}}
}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error' -logfile 'ps1command.log'}